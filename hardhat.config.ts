import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-deploy";

import dotenv from "dotenv"
dotenv.config()


const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.16',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`
      }
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [process.env.DEPLOYER_KEY]
    }
  },
  namedAccounts: {
    deployer: 0,
    owner: 1
  },
  paths: {
    sources: './contracts/', 
    artifacts: "./build/artifacts",
    cache: "./cache",
  },
  typechain: {
    outDir: "./build/typechain/",
    target: "ethers-v5",
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 21
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  }
};

export default config;