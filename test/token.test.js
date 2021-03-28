const hre = require("hardhat");
const { expect } = require("chai");
const { ethers, network } = hre;

describe("Token", function() {
  let tokenDelegate, tokenDelegator, token, masterAddress, minter, account0, account1, account2, account3, initialSupply, allowedAfter, ethereum
  before(async () => {
    masterAddress = "0xb1DC62EC38E6E3857a887210C38418E4A17Da5B2"
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ masterAddress ]
    })
    accounts = await ethers.getSigners()
    minter = ethers.provider.getSigner(masterAddress)

    account0 = accounts[0]
    account1 = accounts[1]
    account2 = accounts[2]
    account3 = accounts[3]

    const TokenDelegate = await ethers.getContractFactory("TokenDelegate")
    tokenDelegate = await TokenDelegate.deploy()

    await tokenDelegate.deployed()

    allowedAfter = 1622505601 // June 1 2021

    initialSupply = ethers.utils.parseEther("1000000000")

    const TokenDelegator = await ethers.getContractFactory("TokenDelegator")
    tokenDelegator = await TokenDelegator
      .deploy(account0.address, tokenDelegate.address, initialSupply, allowedAfter, allowedAfter, false)

    await tokenDelegator.deployed()

    token = await ethers.getContractAt("TokenDelegate", tokenDelegator.address)

    await token.transfer(account1.address, ethers.utils.parseEther("10000"))
    await token.transfer(account2.address, ethers.utils.parseEther("20000"))

    ethereum = network.provider
  })

  it("Should match the deployed", async () => {
    const totalSupply_ = await token.totalSupply()
    const transferPaused_ = await token.transferPaused()
    const name_ = await token.name()
    const symbol_ = await token.symbol()
    expect(totalSupply_).to.be.equal(initialSupply)
    expect(transferPaused_).to.be.equal(false)
    expect(name_).to.be.equal("<Token Name>")
    expect(symbol_).to.be.equal("<TKN>")
  })

  it("Should pause transfer", async () => {
    await token.connect(minter).pauseTransfer()
    const transferPaused_ = await token.transferPaused()
    expect(transferPaused_).to.be.equal(true)
    await expect(token.transfer(account1.address, ethers.utils.parseEther("10000")))
      .to.be.revertedWith("Tkn::_transferTokens: transfer paused")
  })

  it("Should unpause transfer", async () => {
    await token.connect(minter).unpauseTransfer()
    const transferPaused_ = await token.transferPaused()
    expect(transferPaused_).to.be.equal(false)
    await token.transfer(account3.address, ethers.utils.parseEther("10"))
    const balance = await token.balanceOf(account3.address)
    expect(balance).to.be.equal(ethers.utils.parseEther("10"))
  })

  it("Should change name", async () => {
    await token.connect(minter).changeName("Awesome Token")
    const name_ = await token.name()
    expect(name_).to.be.equal("Awesome Token")
  })

  it("Should change symbol", async () => {
    await token.connect(minter).changeSymbol("AWT")
    const name_ = await token.symbol()
    expect(name_).to.be.equal("AWT")
  })

  it("Should delegate", async () => {
    await token.connect(account1).delegate(account3.address)
    const delegate_ = await token.delegates(account1.address)
    expect(delegate_).to.be.equal(account3.address)
  })

  it("Should mint after allowed time", async () => {
    await ethereum.send("evm_setNextBlockTimestamp", [allowedAfter+100])
    await ethereum.send("evm_mine", [])

    const mintAmount = ethers.utils.parseEther("1000")

    await token.connect(minter).mint(account2.address, mintAmount)

    const newTotalSupply = initialSupply.add(mintAmount)

    const totalSupply_ = await token.totalSupply()
    expect(totalSupply_).to.be.equal(newTotalSupply)
  })
})