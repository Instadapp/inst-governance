const hre = require("hardhat");
const RLP = require('rlp');
const { ethers } = hre;

async function main() {
  const deployerAddress = '0x2b02AAd6f1694E7D9c934B7b3Ec444541286cF0f' // Replace this
  const initialSupply = ethers.utils.parseEther("10000000") // Replace with actual supply
  const initialHolder = '0x0000000000000000000000000000000000000002' // Replace
  const mintingAfter = 1622548800 // (June 1) Replace
  const changeImplementationAfter = 1622548800 // (June 1) Replace
  const governanceAdmin = '0x2b02AAd6f1694E7D9c934B7b3Ec444541286cF0f' // Replace this
  const votingPeriod = 6000 // Replace this
  const votingDelay = 1 // Replace this
  const proposalThreshold = ethers.utils.parseEther("60000")
  const timelockDelay = 259200 // (3 Days) Replace this

  const TokenDelegate = await ethers.getContractFactory("TokenDelegate")
  const tokenDelegate = await TokenDelegate.deploy()

  await tokenDelegate.deployed()

  const TokenDelegator = await ethers.getContractFactory("TokenDelegator")
  const tokenDelegator = await TokenDelegator
    .deploy(initialHolder, tokenDelegate.address, initialSupply, mintingAfter, changeImplementationAfter, false)

  await tokenDelegator.deployed()

  const txCount = await ethers.provider.getTransactionCount(deployerAddress) + 2

  const timelockAddress = '0x' + ethers.utils.keccak256(RLP.encode([deployerAddress, txCount])).slice(12).substring(14)

  const GovernorDelegate = await ethers.getContractFactory("GovernorBravoDelegate")
  const governorDelegate = await GovernorDelegate.deploy()

  await governorDelegate.deployed()

  const GovernorDelegator = await ethers.getContractFactory("GovernorBravoDelegator")
  const governorDelegator = await GovernorDelegator
    .deploy(
      timelockAddress,
      governanceAdmin,
      tokenDelegator.address,
      governorDelegate.address,
      votingPeriod,
      votingDelay,
      proposalThreshold
    )
  
  await governorDelegator.deployed()

  const Timelock = await ethers.getContractFactory("Timelock")
  const timelock = await Timelock.deploy(governorDelegator.address, timelockDelay)

  console.log("TokenDelegate: ", tokenDelegate.address)
  console.log("TokenDelegator: ", tokenDelegator.address)
  console.log("Timelock: ", timelock.address)
  console.log("GovernorBravoDelegate: ", governorDelegate.address)
  console.log("GovernorBravoDelegator: ", governorDelegator.address)
  console.log()

  await timelock.deployed()

  await hre.run("verify:verify", {
    address: tokenDelegate.address,
    constructorArguments: []
  })

  await hre.run("verify:verify", {
    address: tokenDelegator.address,
    constructorArguments: [initialHolder, tokenDelegate.address, initialSupply, mintingAfter, changeImplementationAfter, false]
  })

  await hre.run("verify:verify", {
    address: governorDelegate.address,
    constructorArguments: []
  })

  await hre.run("verify:verify", {
    address: governorDelegator.address,
    constructorArguments: [
      timelockAddress,
      governanceAdmin,
      tokenDelegator.address,
      governorDelegate.address,
      votingPeriod,
      votingDelay,
      proposalThreshold
    ]
  })

  await hre.run("verify:verify", {
    address: timelock.address,
    constructorArguments: [governorDelegator.address, timelockDelay]
  })
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
