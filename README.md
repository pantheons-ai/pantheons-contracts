# Contract Testing Instructions
- Copy `.env.example` to `.env` and change `KEY` to your own private key.
- Use Node.js version 20.x. Run `yarn install`.
- Compile the contract: `npx hardhat compile`, to compile the contract.
- Test the contract: `npx hardhat test`, to test the contract. The test file is located at `test/pantheon.ts`.

## Contract Deployment
- `npx hardhat run deploy/deploy.ts --network sepolia`
- `npx hardhat verify --network sepolia 0xeFdaFC2d7a51A1F273FCa25edFe75E0d9A9b74D2 'https://ipfs.io/ipfs/'`