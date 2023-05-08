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
      { name: "value", type: "uint256" },
      { name: "transactionNonce", type: "uint64" },
    ],
  };

  const value = {
    from: await signer.getAddress(),
    to: await signer.getAddress(),
    value: "1",
    transactionNonce: nonce,
  };

  const hashedTypedData = ethers.utils._TypedDataEncoder.hash(
    domain,
    types,
    value
  );
  const signedTypedData = await signer._signTypedData(domain, types, value);

  return { signedTypedData, hashedTypedData };
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
  // const signer2 = (await ethers.getSigners())[1];

  console.log("Signer address:", signer.address, "\n");

  const contract = await deployContract([signer.address], 1);

  const nonce = await getTransactioNonce(contract);

  const { signedTypedData, hashedTypedData } = await signTypedMessage(
    contract.address,
    signer,
    nonce
  );

  console.log({ signedTypedData, hashedTypedData });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
