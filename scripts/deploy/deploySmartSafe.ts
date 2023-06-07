import { ethers } from "hardhat";

async function main() {
  const SmartSafe = await ethers.getContractFactory("SmartSafe");
  const smartSafe = await SmartSafe.deploy();

  await smartSafe.deployed();

  console.log(`SmartSafe deployed to ${smartSafe.address}`);

  const SmartSafeProxyFactory = await ethers.getContractFactory(
    "SmartSafeProxyFactory"
  );

  const smartSafeProxyFactory = await SmartSafeProxyFactory.deploy(
    "0x8E6f42979b5517206Cf9e69A969Fac961D1b36B7",
    smartSafe.address
  );

  await smartSafeProxyFactory.deployed();

  console.log(
    `SmartSafeProxyFactory deployed to ${smartSafeProxyFactory.address}`
  );

  console.log(
    `SmartSafeProxy address: ${await smartSafeProxyFactory.functions.computeAddress(
      "0x8E6f42979b5517206Cf9e69A969Fac961D1b36B7"
    )}`
  );

  await smartSafeProxyFactory.functions.deploySmartSafeProxy(
    [
      "0x8E6f42979b5517206Cf9e69A969Fac961D1b36B7",
      "0x0effBEb3b863b065Bd01De4928f646D611728002",
    ],
    2
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
