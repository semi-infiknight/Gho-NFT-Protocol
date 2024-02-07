import { ethers } from "hardhat";

async function main() {
  const facilitatorContractAddress = "0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7";
  const nftContractAddress = "0x4b07E711e5C9b5bF05e69f8B7fc46F67C81A730A"

  const [signer] = await ethers.getSigners();

  const FacilitatorContract = await ethers.getContractFactory("FacilitatorContract", signer);
  const facilitatorContract = FacilitatorContract.attach(facilitatorContractAddress);

  const borrowed = await facilitatorContract.borrowedAmount(signer.address);
  console.log(`Borrowed for user address ${signer.address}:`, borrowed);

  const borrowPower = await facilitatorContract.borrowPower(signer.address);
  console.log(`Bowwor power for user address ${signer.address}:`, borrowPower);

  const azukiPrice = await facilitatorContract.getNFTPrice(nftContractAddress);
  console.log(`Azuki price:`, azukiPrice);

  const ethPrice = await facilitatorContract.getETHDataFeed();
  console.log(`ETH price:`, ethPrice);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
