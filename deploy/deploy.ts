import { ethers, run } from "hardhat";

async function main() {
  const uri = "https://ipfs.io/ipfs/";
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  const contract = await deployContract("Pantheon", uri);

  console.log(`Verifying contract on Etherscan...`);

  await run(`verify:verify`, {
    address: contract.address,
    constructorArguments: [uri],
  });
}

async function deployContract(contractName: string, ...args: any[]) {
  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(...args);
  const WAIT_BLOCK_CONFIRMATIONS = 1;
  await contract.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
  console.log(`${contractName} Address: `, contract.address);
  return contract;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});