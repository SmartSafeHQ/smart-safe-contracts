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
      { name: "data", type: "bytes" },
      { name: "transactionNonce", type: "uint64" },
    ],
  };

  const value = {
    from: await signer.getAddress(),
    to: "0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005", // ERC20 contract address
    value: ethers.utils.parseUnits("1", "ether").toString(), // 1 ETH
    data: "0xa9059cbb000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb20000000000000000000000000000000000000000000000000de0b6b3a7640000",
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

function decodeHexData() {
  const abi = [
    {
      inputs: [
        {
          internalType: "string",
          name: "name_",
          type: "string",
        },
        {
          internalType: "string",
          name: "symbol_",
          type: "string",
        },
      ],
      stateMutability: "nonpayable",
      type: "constructor",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "owner",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "value",
          type: "uint256",
        },
      ],
      name: "Approval",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "from",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "to",
          type: "address",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "value",
          type: "uint256",
        },
      ],
      name: "Transfer",
      type: "event",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "owner",
          type: "address",
        },
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
      ],
      name: "allowance",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "approve",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "account",
          type: "address",
        },
      ],
      name: "balanceOf",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "decimals",
      outputs: [
        {
          internalType: "uint8",
          name: "",
          type: "uint8",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "subtractedValue",
          type: "uint256",
        },
      ],
      name: "decreaseAllowance",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "addedValue",
          type: "uint256",
        },
      ],
      name: "increaseAllowance",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [],
      name: "name",
      outputs: [
        {
          internalType: "string",
          name: "",
          type: "string",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "symbol",
      outputs: [
        {
          internalType: "string",
          name: "",
          type: "string",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "totalSupply",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "to",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "transfer",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "from",
          type: "address",
        },
        {
          internalType: "address",
          name: "to",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "transferFrom",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
  ];
  new ethers.utils.Interface(abi).decodeErrorResult();
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
