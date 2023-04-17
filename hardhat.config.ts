import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'

const config: HardhatUserConfig = {
  solidity: '0.8.19',
  networks: {
    polygon: {
      chainId: 80001,
      accounts: [
        '0x3e8c49e06a07dae1601ee50f10de0dcc6ef73afae1edca85ba7d598f139cfc9d',
      ],
      url: 'https://rpc.ankr.com/polygon_mumbai',
    },
  },
}

export default config
