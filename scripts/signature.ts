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
    "0xDA0bab807633f07f013f94DD0E6A4F96F8742B53",
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

// function decode() {
//   console.log(
//     "decoded value:",
//     new ethers.utils.AbiCoder().decode(
//       ["uint8", "uint256"],
//       "0x000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000647f9d23"
//     )
//   );
// }

function encode() {
  console.log(
    "encoded value:",
    new ethers.utils.AbiCoder().encode(["uint64"], [0])
  );
}

async function main() {
  const signer = (await ethers.getSigners())[0];
  const signer2 = (await ethers.getSigners())[1];
  const signer3 = (await ethers.getSigners())[2];
  const signer4 = (await ethers.getSigners())[3];

  console.log("Signer address:", signer4.address, "\n");

  const { signedTypedDataHash, typedDataHash } = await signTypedMessage(
    1,
    "0xDA0bab807633f07f013f94DD0E6A4F96F8742B53",
    signer2,
    0
  );

  // decode()
  encode();

  console.log({ signedTypedDataHash, typedDataHash });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
