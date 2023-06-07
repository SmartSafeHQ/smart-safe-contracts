import { ethers } from "hardhat";

async function main() {
  const signer = (await ethers.getSigners())[0];

  const SmartSafe = await ethers.getContractFactory("SmartSafe", signer);

  const smartSafe = await SmartSafe.deploy();

  await smartSafe.deployed();

  console.log(smartSafe.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
