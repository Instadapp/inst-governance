require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

require("dotenv").config();
const ALCHEMY_ID = process.env.ALCHEMY_ID;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.7.3",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
        blockNumber: 12308027,
      },
      blockGasLimit: 12000000,
    },
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_ID}`,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 12500000,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN
  }
};
