import { expect } from "chai";
import { ethers } from "hardhat";
import { Pantheon } from "../typechain-types/Pantheon";
import { ERC404Instance } from "../typechain-types/ERC404Instance";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Pantheon Contract", () => {
  let pantheon: Pantheon;
  let erc404Instance: ERC404Instance;
  let owner: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let user: SignerWithAddress;
  let whitelistAddress: string;

  before(async () => {
    [owner, nonOwner, user] = await ethers.getSigners();
    whitelistAddress = nonOwner.address;

    const PantheonFactory = await ethers.getContractFactory("Pantheon");
    pantheon = await PantheonFactory.deploy("baseURI/");
    await pantheon.deployed();

    // Create an ERC404 instance for testing
    const tx = await pantheon.connect(owner).createERC404(
      "TestToken",
      "TTK",
      18,
      0,
      owner.address
    );
    const receipt = await tx.wait();
    const event = receipt.events?.find(e => e.event === "ERC404Created");
    const erc404Address = event?.args?.contractAddress;
    erc404Instance = await ethers.getContractAt("ERC404Instance", erc404Address) as ERC404Instance;
  });

  describe("Whitelist", () => {
    it("should allow owner to add an address to the whitelist", async () => {
      await expect(pantheon.connect(owner).addToWhitelist(whitelistAddress))
        .to.emit(pantheon, "WhitelistChanged")
        .withArgs(whitelistAddress, true);

      expect(await pantheon.isWhitelisted(whitelistAddress)).to.be.true;
    });

    it("should not allow non-owner to add an address to the whitelist", async () => {
      await expect(pantheon.connect(nonOwner).addToWhitelist(whitelistAddress)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("should allow owner to remove an address from the whitelist", async () => {
      await expect(pantheon.connect(owner).removeFromWhitelist(whitelistAddress))
        .to.emit(pantheon, "WhitelistChanged")
        .withArgs(whitelistAddress, false);

      expect(await pantheon.isWhitelisted(whitelistAddress)).to.be.false;
    });

    it("should not allow non-owner to remove an address from the whitelist", async () => {
      await expect(pantheon.connect(nonOwner).removeFromWhitelist(whitelistAddress)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("CID Management", () => {
    it("should allow whitelisted address to add CIDs", async () => {
      // Add the nonOwner to the whitelist
      await pantheon.connect(owner).addToWhitelist(nonOwner.address);

      // Prepare CIDs to add
      const cids = ["cid1", "cid2", "cid3"];

      // Add CIDs using the Pantheon contract
      await expect(pantheon.connect(nonOwner).addCIDs(0, nonOwner.address, cids))
        .to.emit(erc404Instance, "CIDsAdded")
        .withArgs(nonOwner.address, cids);

      // Verify CIDs were added
      const storedCIDs = await pantheon.connect(nonOwner).getCIDs(0, nonOwner.address);
      expect(storedCIDs).to.deep.equal(cids);
    });

    it("should not allow non-whitelisted address to add CIDs", async () => {
      // Remove the nonOwner from the whitelist
      await pantheon.connect(owner).removeFromWhitelist(nonOwner.address);

      // Prepare CIDs to add
      const cids = ["cid1", "cid2", "cid3"];

      // Attempt to add CIDs without being whitelisted
      await expect(pantheon.connect(nonOwner).addCIDs(0, nonOwner.address, cids))
        .to.be.revertedWith("Caller is not whitelisted");
    });

    it("should allow anyone to get CIDs of a user", async () => {
      // Get CIDs for the nonOwner address
      const storedCIDs = await pantheon.connect(nonOwner).getCIDs(0, nonOwner.address);

      // Verify the correct CIDs are returned
      expect(storedCIDs).to.deep.equal(["cid1", "cid2", "cid3"]);
    });

    it("should allow anyone to get the contribution of a user", async () => {
      // Get contribution for the nonOwner address
      const contribution = await pantheon.connect(nonOwner).getContribution(0, nonOwner.address);

      // Verify the correct contribution count is returned
      expect(contribution).to.equal(3);
    });
  });

  describe("ERC404 Token Transfer and Balance", () => {
    let cids: string[];
    const decimals = 18; // The number of decimals specified when creating the ERC404Instance
    const units = ethers.utils.parseUnits("1", decimals); // This will give us 10^18
  
    before(async () => {
      // Assuming the ERC404Instance has already been created in a previous test
      // and that the owner has some ERC721 and ERC20 tokens minted.
      // erc404Instance should be initialized with the correct contract instance.
  
      // Add some CIDs for the owner to simulate contributions
      cids = ["cid1", "cid2", "cid3"];
      await pantheon.connect(owner).addCIDs(0, user.address, cids);
    });
  
    it("should correctly reflect ERC20 and ERC721 balances based on CIDs", async () => {
      // Check ERC20 balance based on CIDs added
      const erc20Balance = await erc404Instance.erc20BalanceOf(user.address);
      expect(erc20Balance).to.equal(units.mul(cids.length));
  
      // Check ERC721 balance based on CIDs added
      const erc721Balance = await erc404Instance.erc721BalanceOf(user.address);
      expect(erc721Balance).to.equal(cids.length);
    });
  
    it("should correctly transfer ERC20 and ERC721 tokens and update balances", async () => {
      // Transfer some ERC20 tokens from owner to nonOwner
      const transferAmount = units; // 1 unit of ERC20
      const ownerErc20BalanceBefore = await erc404Instance.erc20BalanceOf(user.address);
      const nonOwnerErc20BalanceBefore = await erc404Instance.erc20BalanceOf(nonOwner.address);
      await erc404Instance.connect(user).transfer(nonOwner.address, transferAmount);
  
      // Check ERC20 balances after transfer
      const ownerErc20BalanceAfter = await erc404Instance.erc20BalanceOf(user.address);
      const nonOwnerErc20BalanceAfter = await erc404Instance.erc20BalanceOf(nonOwner.address);
      expect(ownerErc20BalanceAfter).to.equal(ownerErc20BalanceBefore.sub(transferAmount));
      expect(nonOwnerErc20BalanceAfter).to.equal(nonOwnerErc20BalanceBefore.add(transferAmount));
  
      // Transfer an ERC721 token from owner to nonOwner
      const ownedTokens = await erc404Instance.owned(user.address);
      const tokenId = ownedTokens[0];
      
      const ownerErc721BalanceBefore = await erc404Instance.erc721BalanceOf(user.address);
      const nonOwnerErc721BalanceBefore = await erc404Instance.erc721BalanceOf(nonOwner.address);
      await erc404Instance.connect(user).transferFrom(user.address, nonOwner.address, tokenId);
  
      // Check ERC721 balances after transfer
      const ownerErc721BalanceAfter = await erc404Instance.erc721BalanceOf(user.address);
      const nonOwnerErc721BalanceAfter = await erc404Instance.erc721BalanceOf(nonOwner.address);
      expect(ownerErc721BalanceAfter).to.equal(ownerErc721BalanceBefore.sub(1));
      expect(nonOwnerErc721BalanceAfter).to.equal(nonOwnerErc721BalanceBefore.add(1));
    });
  });
});