const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const payload = await ethers.deployContract("PayloadIGP83", [])
  await payload.waitForDeployment()

  console.log("PayloadIGP83: ", payload.target)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
