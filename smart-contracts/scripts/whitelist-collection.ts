import { ethers } from "hardhat";

async function main() {
  const facilitatorAddress = "0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7";

  const collectionAddress = "0x4b07E711e5C9b5bF05e69f8B7fc46F67C81A730A";
  const priceFeedAddress = "0x9F6d70CDf08d893f0063742b51d3E9D1e18b7f74";

  const [deployer] = await ethers.getSigners();

  const FacilitatorContract = await ethers.getContractFactory("FacilitatorContract");
  const facilitatorContract = FacilitatorContract.attach(facilitatorAddress).connect(deployer);

  const tx = await facilitatorContract.whitelistCollection(collectionAddress, priceFeedAddress);
  await tx.wait();

  console.log(`Collection whitelisted successfully. Transaction Hash: ${tx.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
