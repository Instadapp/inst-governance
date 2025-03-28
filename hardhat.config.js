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
    hardhat: {
      forking: {
        url: `https://1rpc.io/eth`,
        blockNumber: 12308027,
      },
      blockGasLimit: 12000000,
    },
    // mainnet: {
    //   url: `https://eth.llamarpc.com`,
    //   accounts: !PRIVATE_KEY ? [] : [ `0x${PRIVATE_KEY}`],
    // },
    mainnet: {
      url: "https://virtual.mainnet.rpc.tenderly.co/27fd1115-d23e-4fcc-82b8-3d417f57f457"
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN
  }
};
