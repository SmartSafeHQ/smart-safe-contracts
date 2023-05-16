import { ethers } from "hardhat";

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
  verifyingContract: string,
  signer: SignerWithAddress,
  nonce: number
) {
  const domain = {
    name: hashString("Smart Safe Signature Manager"),
    version: hashString("1.0.0"),
    chainId: 1,
    verifyingContract:
      "0x047b37Ef4d76C2366F795Fb557e3c15E0607b7d8" || verifyingContract,
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
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0x8207D032322052AfB9Bf1463aF87fd0c0097EDDE",
    nonce,
    "0",
    ethers.utils.keccak256(
      "0xa9059cbb0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000de0b6b3a7640000"
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

  console.log("Signer address:", signer.address, "\n");

  const contract = await deployContract([signer.address], 1);

  const nonce = await getTransactioNonce(contract);

  const { signedTypedDataHash, typedDataHash } = await signTypedMessage(
    contract.address,
    signer,
    nonce
  );

  console.log({ signedTypedDataHash, typedDataHash });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
