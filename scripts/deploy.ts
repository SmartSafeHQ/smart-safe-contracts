import { ethers } from "hardhat";

async function main() {
  const IBRL = await ethers.getContractFactory("IBRL");
  const ibrl = await IBRL.deploy(100_000);

  await ibrl.deployed();

  console.log(
    `IBRL with 100000 IBRL deployed to ${ibrl.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
