import "@nomicfoundation/hardhat-ethers";
import dotenv from "dotenv";
import { defineConfig } from "hardhat/config";
dotenv.config();

export default defineConfig({
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: process.env.ALCHEMY_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
});