const hre = require("hardhat");
const { expect } = require("chai");
const { ethers, network } = hre;

const TokenDelegate = require("../artifacts/contracts/TokenDelegate.sol/InstaTokenDelegate.json")
const Governance = require("../artifacts/contracts/GovernorBravoDelegate.sol/InstaGovernorBravoDelegate.json")

describe("Tests", function() {
  let token, gov, timelock, accounts, account, masterAddress, master, instaIndex, proposor, ethereum

  const instaIndexAbi = [
    'function changeMaster(address _newMaster)',
    'function master() view returns(address)'
  ]

  before(async function() {
    masterAddress = "0xb1DC62EC38E6E3857a887210C38418E4A17Da5B2"
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ masterAddress ]
    })
    accounts = await ethers.getSigners()
    master = ethers.provider.getSigner(masterAddress)
    account = accounts[0]

    proposor = accounts[5]

    token = new ethers.Contract('0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb', TokenDelegate.abi, master)
    gov = new ethers.Contract('0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B', Governance.abi, master)
    instaIndex = new ethers.Contract('0x2971AdFa57b20E5a416aE5a708A8655A9c74f723', instaIndexAbi, master)
    timelock = '0xC7Cb1dE2721BFC0E0DA1b9D526bCdC54eF1C0eFC'

    ethereum = network.provider

    const tx = await token.delegate(masterAddress)
    await tx.wait()
  })

  it("should transfer tokens into 5 addresses", async function() {
    const amt = ethers.utils.parseEther("10000000")
    await token.transfer(accounts[0].address, amt)
    await token.connect(accounts[0]).delegate(accounts[0].address)
    await token.transfer(accounts[1].address, amt)
    await token.connect(accounts[1]).delegate(accounts[1].address)
    await token.transfer(accounts[2].address, amt)
    await token.connect(accounts[2]).delegate(accounts[2].address)
    await token.transfer(accounts[3].address, amt)
    await token.connect(accounts[3]).delegate(accounts[3].address)
    await token.transfer(accounts[4].address, amt)
    await token.connect(accounts[4]).delegate(accounts[4].address)


    expect(await token.balanceOf(accounts[0].address)).to.be.equal(amt)
    expect(await token.balanceOf(accounts[1].address)).to.be.equal(amt)
    expect(await token.balanceOf(accounts[2].address)).to.be.equal(amt)
    expect(await token.balanceOf(accounts[3].address)).to.be.equal(amt)
    expect(await token.balanceOf(accounts[4].address)).to.be.equal(amt)
  })

  it("should create proposal", async function() {
    await instaIndex.changeMaster(timelock)

    const amt = ethers.utils.parseEther("2000000")
    let tx = await token.transfer(proposor.address, amt)

    await tx.wait()

    tx = await token.connect(proposor).delegate(proposor.address)

    await tx.wait()

    await ethereum.send("evm_mine", [])

    tx = await gov.connect(proposor).propose(
      [instaIndex.address],
      [0],
      ['updateMaster()'],
      ['0x'],
      'Activate Governance'
    )

    await tx.wait()

    await ethereum.send("evm_mine", [])
    await ethereum.send("evm_mine", [])
  })

  it("should vote", async function() {
    await gov.connect(accounts[0]).castVote(1, 0)
    await gov.connect(accounts[1]).castVote(1, 1)
    await gov.connect(accounts[2]).castVote(1, 1)
    await gov.connect(accounts[3]).castVote(1, 0)
    await gov.connect(accounts[4]).castVote(1, 1)
  })

  it("should queue the tx", async function() {
    for (let index = 0; index < 17280; index++) {
      await ethereum.send("evm_mine", [])
    }

    const tx = await gov.queue(1)
    await tx.wait()
  })

  it("should execute the tx", async function() {
    const nextTimestamp = Math.floor(Date.now() / 1000) + 172800

    await ethereum.send("evm_setNextBlockTimestamp", [nextTimestamp])
    await ethereum.send("evm_mine", [])

    const tx = await gov.execute(1)
    await tx.wait()

    await ethereum.send("evm_mine", [])

    const newMaster = await instaIndex.master()

    expect(newMaster).to.be.equal(timelock)
  })

  it("should delegate", async function() {
    const votes = await token.getCurrentVotes(proposor.address)

    const delegatingVotes = await token.getCurrentVotes(account.address)

    const tx = await token.connect(account).delegate(proposor.address)
    await tx.wait()

    const newVotes = await token.getCurrentVotes(proposor.address)

    expect(newVotes).to.be.equal(votes.add(delegatingVotes))
  })

  it("should add new proposal", async function() {
    const connectors = '0xFE2390DAD597594439f218190fC2De40f9Cf1179'
    const implementations = '0xCBA828153d3a85b30B5b912e1f2daCac5816aE9D'

    const abiCoder = ethers.utils.defaultAbiCoder

    tx = await gov.connect(proposor).propose(
      [connectors, connectors, instaIndex.address, implementations],
      [0, 0, 0, 0],
      ['addConnectors(string[],address[])', 'toggleChief(address)', 'build(address,uint256,address)', 'addImplementation(address,bytes4[])'],
      [
        abiCoder.encode(
          ['string[]', 'address[]'],
          [
            ['DUMMAY-A', 'DUMMY-B'],
            ['0x6CE3e607C808b4f4C26B7F6aDAeB619e49CAbb25', '0x01fEF4d2B513C9F69E34b2f93Ef707FA9Ff60109']
          ]
        ),
        abiCoder.encode(
          ['address'],
          ['0x1Db3439a222C519ab44bb1144fC28167b4Fa6EE6']
        ),
        abiCoder.encode(
          ['address', 'uint256', 'address'],
          [timelock, 2, timelock]
        ),
        abiCoder.encode(
          ['address', 'bytes4[]'],
          ['0x77a34e565dc4ecedb1a58b4abf96b8ec379b9888', ['0x5a19a5ea']]
        )
      ],
      'Add Connectors, Add VB as Chief, Create a new DSA & Add new implementation'
    )

    await tx.wait()

    await ethereum.send("evm_mine", [])
    await ethereum.send("evm_mine", [])
  })

  it("should vote", async function() {
    await gov.connect(accounts[1]).castVote(2, 1)
    await gov.connect(accounts[2]).castVote(2, 1)
    await gov.connect(accounts[3]).castVote(2, 0)
    await gov.connect(accounts[4]).castVote(2, 1)
  })

  it("should queue the tx", async function() {
    for (let index = 0; index < 17280; index++) {
      await ethereum.send("evm_mine", [])
    }

    const tx = await gov.queue(2)
    await tx.wait()
  })

  it("should execute the tx", async function() {
    const proposal = await gov.proposals(2)
    const eta = proposal.eta

    const nextTimestamp = Number(eta.add(100).toString())

    await ethereum.send("evm_setNextBlockTimestamp", [nextTimestamp])
    await ethereum.send("evm_mine", [])

    const tx = await gov.execute(2, { gasLimit: 12000000 })
    await tx.wait()

    await ethereum.send("evm_mine", [])
  })
})