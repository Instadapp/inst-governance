const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const PayloadIGP83 = await ethers.getContractFactory("PayloadIGP83")
  const payloadIGP83 = await PayloadIGP83.deploy()
  await payloadIGP83.deployed()

  console.log("PayloadIGP83: ", payloadIGP83.address)

  await hre.run("verify:verify", {
    address: payloadIGP83.address,
    constructorArguments: []
  })
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
