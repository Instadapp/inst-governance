const hre = require("hardhat");
const RLP = require('rlp');
const { ethers } = hre;

async function main() {
  const deployerAddress = '0xB46693c062B49689cC4F624AaB24a7eA90275890' // Replace this
  const initialSupply = ethers.utils.parseEther("10000000") // Replace with actual supply
  const initialHolder = '0x0000000000000000000000000000000000000002' // Replace
  const mintingAfter = 1622548800 // (June 1) Replace
  const changeImplementationAfter = 1622548800 // (June 1) Replace
  const governanceAdmin = '0xB46693c062B49689cC4F624AaB24a7eA90275890' // Replace this
  const votingPeriod = 6000 // Replace this
  const votingDelay = 1 // Replace this
  const proposalThreshold = ethers.utils.parseEther("60000")
  const timelockDelay = 259200 // (3 Days) Replace this

  const TokenDelegate = await ethers.getContractFactory("InstaTokenDelegate")
  const tokenDelegate = await TokenDelegate.deploy()

  await tokenDelegate.deployed()

  const TokenDelegator = await ethers.getContractFactory("InstaTokenDelegator")
  const tokenDelegator = await TokenDelegator
    .deploy(initialHolder, tokenDelegate.address, initialSupply, mintingAfter, changeImplementationAfter, false)

  await tokenDelegator.deployed()

  const txCount = await ethers.provider.getTransactionCount(deployerAddress) + 2

  const timelockAddress = '0x' + ethers.utils.keccak256(RLP.encode([deployerAddress, txCount])).slice(12).substring(14)

  const GovernorDelegate = await ethers.getContractFactory("InstaGovernorBravoDelegate")
  const governorDelegate = await GovernorDelegate.deploy()

  await governorDelegate.deployed()

  const GovernorDelegator = await ethers.getContractFactory("InstaGovernorBravoDelegator")
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

  const Timelock = await ethers.getContractFactory("InstaTimelock")
  const timelock = await Timelock.deploy(governorDelegator.address, timelockDelay)

  console.log("InstaTokenDelegate: ", tokenDelegate.address)
  console.log("InstaTokenDelegator: ", tokenDelegator.address)
  console.log("InstaTimelock: ", timelock.address)
  console.log("InstaGovernorBravoDelegate: ", governorDelegate.address)
  console.log("InstaGovernorBravoDelegator: ", governorDelegator.address)
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
