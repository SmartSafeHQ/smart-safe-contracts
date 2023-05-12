import { ethers } from "hardhat";
import { SmartSafe } from "../typechain-types";
import type { SignerWithAddress } from "../node_modules/@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import type { TypedDataDomain, TypedDataField } from "ethers";

async function deployContract(owners: string[], threshold: number) {
  const SmartSafe = await ethers.getContractFactory("SmartSafe");
  const smartSafe = await SmartSafe.deploy(owners, threshold);

  const contract = await smartSafe.deployed();

  console.log(`SmartSafe deployed to ${smartSafe.address}\n`);

  return contract;
}

async function getTransactioNonce(contract: SmartSafe) {
  const nonce = (await contract.functions.transactionNonce()).toString();

  return Number(nonce);
}

async function signTypedMessage(
  verifyingContract: string,
  signer: SignerWithAddress,
  nonce: number
) {
  const domain = {
    name: "Smart Safe Signature Manager",
    version: "1.0.0",
    chainId: 31337,
    verifyingContract,
  };

  const types = {
    Signature: [
      { name: "to", type: "address" },
      { name: "from", type: "address" },
      { name: "transactionNonce", type: "uint64" },
      { name: "value", type: "uint256" },
      { name: "data", type: "bytes" },
    ],
  };

  const value = {
    from: await signer.getAddress(),
    to: "0x3c725134d74D5c45B4E4ABd2e5e2a109b5541288", // ERC20 contract address
    value: "0", // ethers.utils.parseUnits("1", "ether").toString(), // 1 ETH
    data: "0x00b9573b000000000000000000000000617f2e2fd72fd9d5503197092ac168c91465e7f20000000000000000000000000000000000000000000000000000000000000002",
    transactionNonce: nonce,
  };

  const hashedTypedData = ethers.utils._TypedDataEncoder.hash(
    domain,
    types,
    value
  );
  const signature = await signer._signTypedData(domain, types, value);

  return { signature, hashedTypedData };
}

function verifySignedTypedData(
  domain: TypedDataDomain,
  types: Record<string, Array<TypedDataField>>,
  value: Record<string, any>,
  signedTypedData: string
) {
  const address = ethers.utils.verifyTypedData(
    domain,
    types,
    value,
    signedTypedData
  );

  return address;
}

async function decodeHexData() {
  ethers.utils.defaultAbiCoder.decode(
    ["string"],
    "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002645524332303a207472616e7366657220616d6f756e7420657863656564732062616c616e63650000000000000000000000000000000000000000000000000000"
  );
}

// async function checkTransactionSignature(
//   contract: SignatureManager,
//   hashedTypedData: string,
//   signature: string,
//   signerAddress: string
// ) {
//   const response = (
//     await contract.functions.checkTransactionSignature(
//       signerAddress,
//       hashedTypedData,
//       signature
//     )
//   ).toString();

//   return response;
// }

async function main() {
  const signer = (await ethers.getSigners())[0];
  const signer2 = (await ethers.getSigners())[1];

  console.log("Signer address:", signer.address, "\n");

  const contract = await deployContract([signer.address], 1);

  const nonce = await getTransactioNonce(contract);

  const { signature, hashedTypedData } = await signTypedMessage(
    contract.address,
    signer,
    nonce
  );

  console.log({ signature, hashedTypedData });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
