const hre = require("hardhat");
const { expect } = require("chai");
const { ethers, network } = hre;

describe("Token", function() {
  let tokenDelegate, tokenDelegator, token, minter, account1, account2, account3, allowedAfter, ethereum
  before(async () => {
    accounts = await ethers.getSigners()
    minter = accounts[0]

    account1 = accounts[1]
    account2 = accounts[2]
    account3 = accounts[3]

    const TokenDelegate = await ethers.getContractFactory("TokenDelegate")
    tokenDelegate = await TokenDelegate.deploy()

    await tokenDelegate.deployed()

    // console.log((await tokenDelegate.totalSupply()))
    // console.log((await tokenDelegate.symbol()))
    // console.log((await tokenDelegate.decimals()))
    // console.log((await tokenDelegate.transferPaused()))

    allowedAfter = 1622505601 // June 1 2021

    const TokenDelegator = await ethers.getContractFactory("TokenDelegator")
    tokenDelegator = await TokenDelegator.deploy(minter.address, minter.address, tokenDelegate.address, allowedAfter, allowedAfter, false)

    await tokenDelegator.deployed()

    token = await ethers.getContractAt("TokenDelegate", tokenDelegator.address)

    // console.log((await tokenDelegate.balanceOf(minter.address)))

    // console.log((await token.balanceOf(minter.address)))

    await token.transfer(account1.address, ethers.utils.parseEther("10000"))
    await token.transfer(account2.address, ethers.utils.parseEther("20000"))

    ethereum = network.provider
  })

  it("Should match the deployed", async () => {
    const minter_ = await token.minter()
    const totalSupply_ = await token.totalSupply()
    const transferPaused_ = await token.transferPaused()
    const name_ = await token.name()
    const symbol_ = await token.symbol()
    expect(minter_).to.be.equal(minter.address)
    expect(totalSupply_).to.be.equal(ethers.utils.parseEther("10000000"))
    expect(transferPaused_).to.be.equal(false)
    expect(name_).to.be.equal("<Token Name>")
    expect(symbol_).to.be.equal("<TKN>")
  })

  it("Should pause transfer", async () => {
    await token.pauseTransfer()
    const transferPaused_ = await token.transferPaused()
    expect(transferPaused_).to.be.equal(true)
    await expect(token.transfer(account1.address, ethers.utils.parseEther("10000")))
      .to.be.revertedWith("Tkn::_transferTokens: transfer paused")
  })

  it("Should unpause transfer", async () => {
    await token.unpauseTransfer()
    const transferPaused_ = await token.transferPaused()
    expect(transferPaused_).to.be.equal(false)
    await token.transfer(account3.address, ethers.utils.parseEther("10"))
    const balance = await token.balanceOf(account3.address)
    expect(balance).to.be.equal(ethers.utils.parseEther("10"))
  })

  it("Should change name", async () => {
    await token.changeName("Awesome Token")
    const name_ = await token.name()
    expect(name_).to.be.equal("Awesome Token")
  })

  it("Should change symbol", async () => {
    await token.changeSymbol("AWT")
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

    await token.mint(account2.address, ethers.utils.parseEther("1000"))

    const totalSupply_ = await token.totalSupply()
    expect(totalSupply_).to.be.equal(ethers.utils.parseEther("10001000"))
  })
})