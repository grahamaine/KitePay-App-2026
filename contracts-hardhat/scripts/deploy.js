import { ApiKeyStamper } from "@turnkey/api-key-stamper";
import { TurnkeySigner } from "@turnkey/ethers";
import { TurnkeyClient } from "@turnkey/http";
import { ethers } from "ethers";
import hre from "hardhat";

async function main() {
    const ORG_ID = process.env.TURNKEY_ORGANIZATION_ID;
    const PRIVATE_KEY_ID = process.env.TURNKEY_PRIVATE_KEY_ID;
    const API_PUBLIC_KEY = process.env.TURNKEY_API_PUBLIC_KEY;
    const API_PRIVATE_KEY = process.env.TURNKEY_API_PRIVATE_KEY;

    // RPC URL per network
    const RPC_URLS = {
        kiteTestnet: "https://rpc-testnet.gokite.ai/",
        kiteMainnet: "https://rpc.gokite.ai/",
        sepolia: "https://rpc.sepolia.org",
    };
    const networkName = hre.network.name;
    const rpcUrl = process.env.KITE_TESTNET_RPC_URL ?? RPC_URLS[networkName] ?? RPC_URLS.kiteTestnet;

    console.log("Network:", networkName);
    console.log("RPC    :", rpcUrl);

    const turnkeyClient = new TurnkeyClient(
        { baseUrl: "https://api.turnkey.com" },
        new ApiKeyStamper({ apiPublicKey: API_PUBLIC_KEY, apiPrivateKey: API_PRIVATE_KEY })
    );
    const turnkeySigner = new TurnkeySigner({
        client: turnkeyClient,
        organizationId: ORG_ID,
        signWith: PRIVATE_KEY_ID,
    });

    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const signer = turnkeySigner.connect(provider);
    const address = await signer.getAddress();
    const balance = await provider.getBalance(address);
    const network = await provider.getNetwork();

    console.log("ChainId :", network.chainId.toString());
    console.log("Deployer:", address);
    console.log("Balance :", ethers.formatEther(balance), "KITE");

    if (balance === 0n) {
        console.warn("⚠️  0 balance — get tokens: https://faucet.gokite.ai");
    }

    const artifact = await hre.artifacts.readArtifact("KitePayToken");
    const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, signer);

    console.log("\n⏳ Deploying KitePayToken...");
    const contract = await factory.deploy();
    await contract.waitForDeployment();

    const deployed = await contract.getAddress();
    console.log("\n✅ Deployed:", deployed);
    console.log("🔗 https://testnet.kitescan.ai/address/" + deployed);
    console.log("\n💡 Add to .env: KITE_TOKEN_ADDRESS=" + deployed);
}

main().then(() => process.exit(0)).catch(e => { console.error("❌", e.message ?? e); process.exit(1); });