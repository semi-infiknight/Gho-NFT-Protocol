import { ethers } from "hardhat";

async function main() {
  const nftContractAddress = "0x4b07E711e5C9b5bF05e69f8B7fc46F67C81A730A";
  const operatorAddress = "0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7";

  const [signer] = await ethers.getSigners();

  const NFTContract = await ethers.getContractAt("IERC721", nftContractAddress, signer);

  const revokeTx = await NFTContract.setApprovalForAll(operatorAddress, false);
  await revokeTx.wait();

  console.log(`Approval for all revoked for operator ${operatorAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
