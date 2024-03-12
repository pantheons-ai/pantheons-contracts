import { ethers, run } from "hardhat";

async function main() {
  const uri = "https://ipfs.io/ipfs/";
  const StoryProtocolGateway = "0xf82EEe73c2c81D14DF9bC29DC154dD3c079d80a0";
  const IPAssetRegistry = "0x292639452A975630802C17c9267169D93BD5a793"
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  const contract = await deployContract("Pantheon", uri, StoryProtocolGateway, IPAssetRegistry, 0);

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