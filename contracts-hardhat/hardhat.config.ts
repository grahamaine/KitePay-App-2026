import "@nomicfoundation/hardhat-ethers";
import * as dotenv from "dotenv";
import { defineConfig } from "hardhat/config";

dotenv.config({ path: "../.env" });

export default defineConfig({
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    hardhat: {
      type: "edr-simulated",
    },
    kiteTestnet: {
      type: "http",
      url: process.env.KITE_TESTNET_RPC_URL ?? "https://rpc-testnet.gokite.ai/",
      chainId: 2368,
    },
    kiteMainnet: {
      type: "http",
      url: process.env.KITE_MAINNET_RPC_URL ?? "https://rpc.gokite.ai/",
      chainId: 2366,
    },
    sepolia: {
      type: "http",
      url: process.env.SEPOLIA_RPC_URL ?? "https://rpc.sepolia.org",
      chainId: 11155111,
    },
  },
});