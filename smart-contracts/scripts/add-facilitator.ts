import { ethers } from "hardhat";

async function main() {
  const ghoTokenAddress = "0x135512F8864B91015C3Bf913215d91c0317Ae91E";
  const facilitatorAddress = "0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7";
  const bucketCapacity = ethers.utils.parseUnits("10000000", 18);

  const [deployer] = await ethers.getSigners();

  const GhoToken = await ethers.getContractFactory("GhoToken");
  const ghoToken = GhoToken.attach(ghoTokenAddress).connect(deployer);

  const tx = await ghoToken.addFacilitator(facilitatorAddress, "NFT Facilitator", bucketCapacity);
  await tx.wait();

  console.log(`Facilitator added successfully. Transaction Hash: ${tx.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
