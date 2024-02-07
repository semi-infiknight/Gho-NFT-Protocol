import { ethers } from "hardhat";

async function main() {
  const burnContractAddress = "0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7";
  const burnAmount = ethers.utils.parseUnits("5000", 18);

  const [signer] = await ethers.getSigners();

  const BurnContract = await ethers.getContractFactory("FacilitatorContract", signer);
  const burnContract = BurnContract.attach(burnContractAddress);

  const burnTx = await burnContract.repayGho(burnAmount);
  await burnTx.wait();
  console.log(`Burned ${burnAmount} GHO tokens. Transaction Hash: ${burnTx.hash}`);

}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
