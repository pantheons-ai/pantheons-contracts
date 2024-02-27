# Contract Testing Instructions
- Copy `.env.example` to `.env` and change `KEY` to your own private key.
- Use Node.js version 20.x. Run `yarn install`.
- Compile the contract: `npx hardhat compile`, to compile the contract.
- Test the contract: `npx hardhat test`, to test the contract. The test file is located at `test/pantheon.ts`.