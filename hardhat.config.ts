import 'dotenv/config'
import "@nomicfoundation/hardhat-ignition-ethers";
import { HardhatUserConfig } from "hardhat/config";
import { HttpNetworkUserConfig } from "hardhat/types";
import * as tenderly from "@tenderly/hardhat-tenderly";

const  {
  DEPLOYER_PRIVATE_KEY,
  ETHERSCAN_API_KEY,
} = process.env

const sharedNetworkConfig: HttpNetworkUserConfig = {
  accounts: [DEPLOYER_PRIVATE_KEY as string],
};

const config = {
  solidity: {
    compilers: [
      {
        version: "0.7.3",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      },
      {
        version: "0.8.21",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      }
    ]
  },
  networks: {
    "mainnet": {
      chainId: 1,
      url: "https://rpc.ankr.com/eth",
      ...sharedNetworkConfig,
    },
    "tenderly": {
      url: `https://virtual.mainnet.rpc.tenderly.co/79b4f880-0837-402b-a2e4-0be0005b8fd9`
    },
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY || "",
    },
  },
  ignition: {
    strategyConfig: {
      create2: {
        // To learn more about salts, see the CreateX documentation: https://github.com/pcaversaccio/createx
        salt: "0x0000000000000000000000000000000000000000000000000000000000000001",
      },
    },
  },
  tenderly: {
    username: "InstaDApp", // tenderly username (or organization name)
    project: "fluid", // project name
  }
};

export default config;

