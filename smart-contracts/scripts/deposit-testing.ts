import { ethers } from "hardhat";

async function main() {
  const facilitatorContractAddress = "0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7";
  const ghoTokenAddress = "0x135512F8864B91015C3Bf913215d91c0317Ae91E";
  const nftContractAddress = "0x4b07E711e5C9b5bF05e69f8B7fc46F67C81A730A";
  const tokenId = 0;

  const [signer] = await ethers.getSigners();

  const nftContract = new ethers.Contract(nftContractAddress, [
    "function approve(address to, uint256 tokenId) external"
  ], signer);

  const approveTx = await nftContract.approve(facilitatorContractAddress, tokenId);
  await approveTx.wait();
  console.log("NFT transfer approved");

  const FacilitatorContract = await ethers.getContractFactory("FacilitatorContract", signer);
  const facilitatorContract = FacilitatorContract.attach(facilitatorContractAddress);

  const priceFeedAddress = await facilitatorContract.collections(nftContractAddress);
  console.log(`Price Feed Address for ${nftContractAddress}: ${priceFeedAddress}`);

  const depositTx = await facilitatorContract.depositNFT(nftContractAddress, tokenId);
  await depositTx.wait();
  console.log(`Successfully deposited, Transaction Hash: ${depositTx.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
