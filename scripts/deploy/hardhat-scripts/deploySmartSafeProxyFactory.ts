import { ethers, network } from "hardhat";
import { config } from "dotenv";

config();

async function main() {
  const signer = (await ethers.getSigners())[0];

  const SmartSafeProxyAddress = await ethers.getContractFactory(
    "SmartSafeProxyFactory",
    signer
  );

  const parsedEnvFile = process.env[`SMART_SAFE_IMPLEMENTATION_${network.name.toUpperCase()}`];

  if (!parsedEnvFile) {
    throw new Error(
      `Smart Safe Implementation address for ${network.name} network not found`
    );
  }

  const smartSafeProxyAddress = await SmartSafeProxyAddress.deploy(
    signer.address,
    parsedEnvFile
  );

  await smartSafeProxyAddress.deployed();

  console.log(smartSafeProxyAddress.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
