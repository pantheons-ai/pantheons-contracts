import { expect } from "chai";
import { ethers } from "hardhat";
import { Pantheon } from "../typechain-types/Pantheon";
import { ERC404Instance } from "../typechain-types/ERC404Instance";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Pantheon Contract", () => {
  let pantheon: Pantheon;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;

  before(async () => {
    [owner, user] = await ethers.getSigners();

    const PantheonFactory = await ethers.getContractFactory("Pantheon");
    pantheon = await PantheonFactory.deploy("baseURI/", "0xf82EEe73c2c81D14DF9bC29DC154dD3c079d80a0", "0x292639452A975630802C17c9267169D93BD5a793", 0);
    await pantheon.deployed();
  });

  // describe("ERC404 Instance Creation", () => {
  //   it("should allow creation of a new ERC404 instance", async () => {
  //     try {
  //       const tx = await pantheon.connect(owner).createERC404(
  //         "TestToken",
  //         "TTK",
  //         18,
  //         1000,
  //         owner.address,
  //         "NFT Description",
  //         "NFT URL",
  //         "NFT Image",
  //         ["key1", "key2"],
  //         ["value1", "value2"],
  //         "IP Name",
  //         ethers.utils.formatBytes32String("IP Hash"),
  //         "IP URL",
  //         ["ipKey1", "ipKey2"],
  //         ["ipValue1", "ipValue2"]
  //       );
  //       const receipt = await tx.wait();
  //       const event = receipt.events?.find(e => e.event === "ERC404Created");
  //       expect(event).to.not.be.undefined;
  //     } catch (error) {
  //       console.error(error);
  //     }
  //   });
  // });

  describe("Whitelist Management", () => {
    it("should allow owner to add and remove an address from the whitelist", async () => {
      await expect(pantheon.connect(owner).addToWhitelist(user.address))
        .to.emit(pantheon, "WhitelistChanged")
        .withArgs(user.address, true);

      expect(await pantheon.isWhitelisted(user.address)).to.be.true;

      await expect(pantheon.connect(owner).removeFromWhitelist(user.address))
        .to.emit(pantheon, "WhitelistChanged")
        .withArgs(user.address, false);

      expect(await pantheon.isWhitelisted(user.address)).to.be.false;
    });
  });

  describe("CID Management", () => {
    let erc404Instance: ERC404Instance;

    before(async () => {
      // Create an ERC404 instance for testing
      const tx = await pantheon.connect(owner).createERC404(
        "TestToken",
        "TTK",
        18,
        1000,
        owner.address,
        "NFT Description",
        "NFT URL",
        "NFT Image",
        ["key1", "key2"],
        ["value1", "value2"],
        "IP Name",
        ethers.utils.formatBytes32String("IP Hash"),
        "IP URL",
        ["ipKey1", "ipKey2"],
        ["ipValue1", "ipValue2"]
      );
      const receipt = await tx.wait();
      const event = receipt.events?.find(e => e.event === "ERC404Created");
      const erc404Address = event?.args?.contractAddress;
      erc404Instance = await ethers.getContractAt("ERC404Instance", erc404Address) as ERC404Instance;
    });

    it("should allow whitelisted address to add and retrieve CIDs", async () => {
      // Add the user to the whitelist
      await pantheon.connect(owner).addToWhitelist(user.address)
      .to.emit(pantheon, "WhitelistChanged")
      .withArgs(user.address, true);

      // Prepare CIDs to add
      const cids = ["cid1", "cid2", "cid3"];

      // Add CIDs using the Pantheon contract
      await expect(pantheon.connect(user).addCIDs(0, user.address, cids))
        .to.emit(erc404Instance, "CIDsAdded")
        .withArgs(user.address, cids);

      // Verify CIDs were added
      const storedCIDs = await pantheon.connect(user).getCIDs(0, user.address);
      expect(storedCIDs).to.deep.equal(cids);

      // Get contribution for the user address
      const contribution = await pantheon.connect(user).getContribution(0, user.address);
      expect(contribution).to.equal(cids.length);
    });
  });
});