import hre from "hardhat";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const Token = await hre.ethers.getContractFactory("KitePayToken");
  const token = await Token.deploy();
  await token.waitForDeployment();

  const address = await token.getAddress();
  console.log("KitePayToken deployed to:", address);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});