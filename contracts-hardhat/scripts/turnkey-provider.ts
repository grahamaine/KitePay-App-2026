import "@nomicfoundation/hardhat-toolbox";
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
            type: "hardhat",
        },
        sepolia: {
            type: "http",
            url: process.env.SEPOLIA_RPC_URL ?? "https://rpc.sepolia.org",
            chainId: 11155111,
        },
        baseSepolia: {
            type: "http",
            url: process.env.BASE_SEPOLIA_RPC_URL ?? "https://sepolia.base.org",
            chainId: 84532,
        },
        amoy: {
            type: "http",
            url: process.env.AMOY_RPC_URL ?? "https://rpc-amoy.polygon.technology",
            chainId: 80002,
        },
        mainnet: {
            type: "http",
            url: process.env.MAINNET_RPC_URL ?? "https://cloudflare-eth.com",
            chainId: 1,
        },
    },
});