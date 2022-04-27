require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

const privateKey = process.env.PRIVATE_KEY;

module.exports = {
  defaultNetwork: "polygon_testnet",

  networks: {
    hardhat: {},
    polygon_testnet: {
      url: "https://rpc-mumbai.maticvigil.com",
      chainId: 80001,
      accounts: [`0x${privateKey}`],
    },
    polygon_mainnet: {
      url: "https://polygon-rpc.com",
      accounts: [`0x${privateKey}`],
    },
  },
  solidity: {
    version: "0.8.2",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
};
