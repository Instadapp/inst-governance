const hre = require("hardhat");
const RLP = require('rlp');
const { ethers } = hre;

async function main() {
  const deployerAddress = '0xB46693c062B49689cC4F624AaB24a7eA90275890' // Replace this
  const initialSupply = ethers.utils.parseEther("100000000") // 100M supply
  const initialHolder = '0x0000000000000000000000000000000000000002' // Replace
  const mintingAfter = 1743465600 // Thursday, 1 May 2025 00:00:00 // TODO - replace
  const governanceAdmin = '0xB46693c062B49689cC4F624AaB24a7eA90275890' // Replace this
  const votingPeriod = 17280 // ~3 days in blocks (assuming 15s blocks)
  const votingDelay = 1 // 1 block
  const proposalThreshold = ethers.utils.parseEther("1000000") // 1M
  const timelockDelay = 172800 // ~2 days in blocks (assuming 15s blocks)

  const TokenDelegate = await ethers.getContractFactory("InstaTokenDelegate")
  const tokenDelegate = await TokenDelegate.deploy()

  await tokenDelegate.deployed()

  const TokenDelegator = await ethers.getContractFactory("InstaTokenDelegator")
  const tokenDelegator = await TokenDelegator
    .deploy(initialHolder, tokenDelegate.address, initialSupply, mintingAfter, false)

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

  await timelock.deployed()

  console.log("InstaTokenDelegate: ", tokenDelegate.address)
  console.log("InstaTokenDelegator: ", tokenDelegator.address)
  console.log("InstaTimelock: ", timelock.address)
  console.log("InstaGovernorBravoDelegate: ", governorDelegate.address)
  console.log("InstaGovernorBravoDelegator: ", governorDelegator.address)
  console.log()

  await hre.run("verify:verify", {
    address: tokenDelegate.address,
    constructorArguments: []
  })

  await hre.run("verify:verify", {
    address: tokenDelegator.address,
    constructorArguments: [initialHolder, tokenDelegate.address, initialSupply, mintingAfter, false]
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
