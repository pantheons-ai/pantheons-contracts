import { ethers, run } from "hardhat";

async function main() {
}

async function deployContract(contractName: string, ...args: any[]) {
  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(...args);
  console.log(`${contractName} Address: `, contract.address);
  return contract;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});