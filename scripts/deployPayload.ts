import { ethers, tenderly } from "hardhat";

async function main() {
  const payload = await ethers.deployContract("PayloadIGP83");

  await payload.waitForDeployment();

  console.log(
    `Payload deployed to ${payload.target}`
  );

  await tenderly.verify({
    name: 'PayloadIGP83',
    address: await payload.getAddress(),
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});