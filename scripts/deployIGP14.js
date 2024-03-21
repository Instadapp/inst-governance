const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  // const PayloadIGP14 = await ethers.getContractFactory("PayloadIGP14")
  // const payloadIGP14 = await PayloadIGP14.deploy()
  // await payloadIGP14.deployed()

  // console.log("PayloadIGP14: ", payloadIGP14.address)

  await hre.run("verify:verify", {
    address: "0x9C5F9e5987EBc5cb589215d6cE9Af8FE72560AE8",
    constructorArguments: []
  })
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
