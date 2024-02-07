import { HardhatUserConfig } from "hardhat/config";
import { config } from 'dotenv';
import "@nomicfoundation/hardhat-toolbox";

config();

const hardhatConfig: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.GOERLI_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  }
};

export default hardhatConfig;
