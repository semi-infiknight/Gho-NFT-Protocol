import { ethers } from "hardhat";

async function main() {
  const ghoTokenAddress = "0x135512F8864B91015C3Bf913215d91c0317Ae91E";

  const [deployer] = await ethers.getSigners();

  const GhoToken = await ethers.getContractFactory("GhoToken");
  const ghoToken = GhoToken.attach(ghoTokenAddress).connect(deployer);

  const FACILITATOR_MANAGER_ROLE = ethers.utils.id("FACILITATOR_MANAGER_ROLE");

  console.log(`Assigning FACILITATOR_MANAGER_ROLE to ${deployer.address}...`);

  const tx = await ghoToken.grantRole(FACILITATOR_MANAGER_ROLE, deployer.address);
  await tx.wait();

  console.log(`Role assigned successfully to ${deployer.address}. Transaction Hash: ${tx.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
