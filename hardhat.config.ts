import { HardhatUserConfig, task } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomiclabs/hardhat-ethers'
require("@nomiclabs/hardhat-etherscan");
import dotenv from 'dotenv'

dotenv.config()

// const commonConfig = {
//   gas: 5_000_000,
//   accounts: {
//     mnemonic: process.env.MNEMONIC || ''
//   }
// }

const { KEY } = process.env;
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    localhost: {
      gas: 1_400_000
    },
    // baobab: {
    //   url: 'https://api.baobab.klaytn.net:8651',
    //   ...commonConfig,
    //   gasPrice: 250_000_000_000
    // },
    // cypress: {
    //   url: 'https://public-en-cypress.klaytn.net',
    //   ...commonConfig,
    //   gasPrice: 250_000_000_000
    // },
    // bscTestnet: {
    //   url: "https://bsc-testnet.public.blastapi.io",
    //   chainId: 97,
    //   accounts: [`0x${KEY}`],
    // },
    // mumbai: {
    //   url: 'https://polygon-mumbai-bor.publicnode.com',
    //   chainId: 80001,
    //   accounts: [`0x${KEY}`]      
    // },
    sepolia: {
      url: 'https://eth-sepolia.g.alchemy.com/v2/qdH89-Ntk7QWTUUvfdWXrYh39e0nKJrw',
      chainId: 11155111,
      accounts: [`0x${KEY}`]      
    },
  },
  etherscan: {
    apiKey: "qdH89-Ntk7QWTUUvfdWXrYh39e0nKJrw",
  },
}

export default config