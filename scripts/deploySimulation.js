const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const payload = await ethers.deployContract("PayloadIGP15", [])
  await payload.waitForDeployment()

  console.log("PayloadIGP15: ", payload.target)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
