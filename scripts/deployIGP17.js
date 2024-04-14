const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const PayloadIGP17 = await ethers.getContractFactory("PayloadIGP17")
  const payloadIGP17 = await PayloadIGP17.deploy()
  await payloadIGP17.deployed()

  console.log("PayloadIGP17: ", payloadIGP17.address)

  await hre.run("verify:verify", {
    address: payloadIGP17.address,
    constructorArguments: []
  })
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
