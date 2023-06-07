import { promisify } from "node:util";
import { exec as callback_exec } from "node:child_process";
import { appendFile, rm } from "node:fs/promises";
import { resolve } from "node:path";
import { ethers } from "hardhat";
import yargs from "yargs";
import { config } from "dotenv";

config();

const exec = promisify(callback_exec);

const addresses: Record<string, Record<string, string>> = {};

async function deleteEnvFile() {
  try {
    await rm(resolve(".env"));
  } catch (err) {
    const error = err as Error & { code: string };
    if (error.code !== "ENOENT") {
      console.log(err);
    }
  }
}

async function deploySmartSafeImplementation(network: string) {
  try {
    const smartSafeDeployment = await exec(
      `npx hardhat run --network ${network} scripts/deploy/hardhat-scripts/deploySmartSafe.ts`
    );

    await appendFile(
      resolve(".env"),
      `SMART_SAFE_IMPLEMENTATION_${network.toUpperCase()}=${smartSafeDeployment.stdout.trim()}\n`
    );

    addresses[network.toUpperCase()] = {
      ...addresses[network.toUpperCase()],
      implementation: smartSafeDeployment.stdout.trim(),
    };

    return smartSafeDeployment.stdout.trim();
  } catch (err) {
    console.log(err);
    addresses[network.toUpperCase()] = {
      implementation: "error",
    };
  }
}

async function deploySmartSafeProxyFactory(network: string) {
  try {
    const smartSafeProxyFactoryDeployment = await exec(
      `npx hardhat run --network ${network} scripts/deploy/hardhat-scripts/deploySmartSafeProxyFactory.ts`
    );

    await appendFile(
      resolve(".env"),
      `SMART_SAFE_PROXY_FACTORY_${network.toUpperCase()}=${smartSafeProxyFactoryDeployment.stdout.trim()}\n`
    );

    addresses[network.toUpperCase()] = {
      ...addresses[network.toUpperCase()],
      proxy: smartSafeProxyFactoryDeployment.stdout.trim(),
    };
  } catch (err) {
    console.log(err);
    addresses[network.toUpperCase()] = {
      proxy: "error",
    };
  }
}

async function updateSmartSafeImplementationAddress(
  network: string,
  smartSafeProxyFactoryAddress: string,
  newSmartSafeImplementationAddress: string
) {
  try {
    const signer = (await ethers.getSigners())[0];
    const contract = await ethers.getContractAt(
      "SmartSafeProxyFactory",
      smartSafeProxyFactoryAddress,
      signer
    );

    const transaction = await contract.functions.setSmartSafeImplementation(
      newSmartSafeImplementationAddress
    );

    await transaction.wait();

    addresses[network.toUpperCase()] = {
      ...addresses[network.toUpperCase()],
      implementation: newSmartSafeImplementationAddress,
    };
  } catch (err) {
    console.log(err);
  }
}

async function parseArgs() {
  const argv = await yargs(process.argv.slice(2)).argv;

  return argv;
}

async function main() {
  const action = await parseArgs();

  const networks = [/*'polygon',  "bnb"*/ "okt" /*'sepolia'*/];

  if (action["update"]) {
    for (const network of networks) {
      const smartSafeProxyFactoryAddress =
        process.env[`SMART_SAFE_PROXY_FACTORY_${network.toUpperCase()}`];

      if (!smartSafeProxyFactoryAddress) {
        throw new Error("Smart Safe Proxy Address not found");
      }

      const smartSafeImplementationAddress =
        await deploySmartSafeImplementation(network);

      if (!smartSafeImplementationAddress) {
        throw new Error("Smart Safe Implementation address is undefined");
      }

      await updateSmartSafeImplementationAddress(
        network,
        smartSafeProxyFactoryAddress,
        smartSafeImplementationAddress
      );
    }
  } else if (action["deploy"]) {
    await deleteEnvFile();

    for (const network of networks) {
      await deploySmartSafeImplementation(network);

      await deploySmartSafeProxyFactory(network);
    }
  }

  console.table(addresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
