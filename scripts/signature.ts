import { ethers } from "hardhat";
import { randomBytes } from "node:crypto";

import SMART_SAFE_ABI from "./utils/SmartSafeABI.json";
import type { SmartSafe } from "../typechain-types";
import type { SignerWithAddress } from "../node_modules/@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

async function deployContract(owners: string[], threshold: number) {
  const SmartSafe = await ethers.getContractFactory("SmartSafe");
  const smartSafe = await SmartSafe.deploy();

  const contract = await smartSafe.deployed();

  await contract.setupOwners(owners, threshold);

  console.log(`SmartSafe deployed to ${smartSafe.address}\n`);

  return contract;
}

async function getTransactioNonce(contract: SmartSafe) {
  const nonce = (await contract.functions.transactionNonce()).toString();

  return Number(nonce);
}

async function decodeHexData() {
  new ethers.utils.AbiCoder().decode(
    ["string"],
    "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002645524332303a207472616e7366657220616d6f756e7420657863656564732062616c616e63650000000000000000000000000000000000000000000000000000"
  );
}

function hashString(data: string) {
  const stringToBytes = ethers.utils.toUtf8Bytes(data);
  return ethers.utils.keccak256(stringToBytes);
}

function calculateSalt() {
  return ethers.utils.keccak256(randomBytes(32));
}

function parseContractErrorEvent() {
  const iface = new ethers.utils.Interface(SMART_SAFE_ABI);

  return iface.parseError("0xe6c4247b");
}

function getHashOfSignatureStruct(
  from: string,
  to: string,
  transactioNonce: number,
  value: string,
  data: string
) {
  const signatureStructHash = hashString(
    "Signature(address,address,uint64,uint256,bytes)"
  );

  const signatureStructEncoded = new ethers.utils.AbiCoder().encode(
    ["bytes32", "address", "address", "uint64", "uint256", "bytes32"],
    [signatureStructHash, from, to, transactioNonce, value, data]
  );

  const hashedEncodedStruct = ethers.utils.keccak256(signatureStructEncoded);

  return { hashedEncodedStruct };
}

async function signTypedMessage(
  chainId: number,
  verifyingContract: string,
  signer: SignerWithAddress,
  nonce: number
) {
  const domain = {
    name: hashString("Smart Safe Signature Manager"),
    version: hashString("1.0.0"),
    chainId,
    verifyingContract,
  };

  const types = {
    Signature: [
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "transactionNonce", type: "uint64" },
      { name: "value", type: "uint256" },
      { name: "data", type: "bytes32" },
    ],
  };

  const values = {
    from: verifyingContract,
    to: "0xd9145CCE52D386f254917e481eB44e9943F39138",
    transactionNonce: nonce,
    value: "0",
    data: ethers.utils.keccak256(
      "0x00b9573b0000000000000000000000004b20993bc481177ec7e8f571cecae8a9e22c02db0000000000000000000000000000000000000000000000000000000000000002"
    ),
  };

  const typeHash = hashString(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  );

  const domainSeparator = ethers.utils.keccak256(
    new ethers.utils.AbiCoder().encode(
      ["bytes32", "bytes32", "bytes32", "uint256", "address"],
      [
        typeHash,
        domain.name,
        domain.version,
        domain.chainId,
        domain.verifyingContract,
      ]
    )
  );

  const { hashedEncodedStruct } = getHashOfSignatureStruct(
    verifyingContract, // always the Smart Safe address
    "0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47",
    nonce,
    "0", //ethers.utils.parseEther("1").toString(),
    ethers.utils.keccak256(
      "0x00b9573b0000000000000000000000004b20993bc481177ec7e8f571cecae8a9e22c02db0000000000000000000000000000000000000000000000000000000000000002"
    )
  );

  const typedDataHash = ethers.utils.keccak256(
    ethers.utils.solidityPack(
      ["string", "bytes32", "bytes32"],
      ["\x19\x01", domainSeparator, hashedEncodedStruct]
    )
  );

  const signedTypedDataHash = await signer.signMessage(
    ethers.utils.arrayify(typedDataHash)
  );

  return { typedDataHash, signedTypedDataHash };
}

async function main() {
  const signer = (await ethers.getSigners())[0];
  const signer2 = (await ethers.getSigners())[1];
  const signer3 = (await ethers.getSigners())[2];

  console.log("Signer address:", signer.address, "\n");
  console.log("SALT", calculateSalt());

  const contract = await deployContract([signer.address], 1);

  const nonce = await getTransactioNonce(contract);

  const { signedTypedDataHash, typedDataHash } = await signTypedMessage(
    1,
    "0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47",
    signer2,
    0
  );

  console.log({ signedTypedDataHash, typedDataHash });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
