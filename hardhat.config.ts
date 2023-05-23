import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000000,
      },
    },
  },
  defaultNetwork: "hardhat",
  contractSizer: {
    runOnCompile: true,
  },
  networks: {
    hardhat: {
      // these are the Remix IDE accounts
      // https://github.com/ethereum/remix-project/blob/d13fea7e8429436de6622d855bf75688c664a956/libs/remix-simulator/src/methods/accounts.ts#L22
      accounts: [
        {
          balance: "1000000000000000000000",
          privateKey:
            "0x503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb",
        },
        {
          balance: "1000000000000000000000",
          privateKey:
            "0x7e5bfb82febc4c2c8529167104271ceec190eafdca277314912eaabdb67c6e5f",
        },
        {
          balance: "1000000000000000000000",
          privateKey:
            "cc6d63f85de8fef05446ebdd3c537c72152d0fc437fd7aa62b3019b79bd1fdd4",
        },
      ],
    },
    polygon: {
      chainId: 80001,
      accounts: [
        "0x3e8c49e06a07dae1601ee50f10de0dcc6ef73afae1edca85ba7d598f139cfc9d",
      ],
      url: "https://rpc.ankr.com/polygon_mumbai",
    },
  },
};

export default config;
