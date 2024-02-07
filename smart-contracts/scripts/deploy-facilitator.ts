import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const ghoTokenAddress = "0x135512F8864B91015C3Bf913215d91c0317Ae91E";

  console.log(
    `Deploying contract with the account: ${deployer.address}`
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const FacilitatorContract = await ethers.getContractFactory("FacilitatorContract");
  const facilitatorContract = await FacilitatorContract.deploy(ghoTokenAddress, deployer.address);
  await facilitatorContract.deployed();
  console.log("FacilitatorContract deployed to:", facilitatorContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
