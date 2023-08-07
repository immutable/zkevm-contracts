import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ImmutableERC721PermissionedMintable__factory,
  ImmutableERC721PermissionedMintable,
  RoyaltyAllowlist,
  RoyaltyAllowlist__factory
} from "../../../typechain";
import {
    AllowlistFixture,
} from "../../utils/DeployFixtures";

describe("Immutable ERC721 Permissioned Mintable Test Cases", function () {
    this.timeout(300_000); // 5 min
  
    let erc721: ImmutableERC721PermissionedMintable;
    let royaltyAllowlist: RoyaltyAllowlist;
    let owner: SignerWithAddress;
    let user: SignerWithAddress;
    let user2: SignerWithAddress;
    let minter: SignerWithAddress;
    let registrar: SignerWithAddress;
    let royaltyRecipient: SignerWithAddress;
    let adminOne: SignerWithAddress;
    let adminTwo: SignerWithAddress;
  
    const baseURI = "https://baseURI.com/";
    const contractURI = "https://contractURI.com";
    const name = "ERC721Preset";
    const symbol = "EP";
    const royalty = ethers.BigNumber.from("2000");
  
    before(async function () {
      // Retrieve accounts
      [owner, user, minter, registrar, royaltyRecipient, adminOne, adminTwo, user2] =
        await ethers.getSigners();

      // Get all required contracts
      ({ erc721, royaltyAllowlist } =
        await AllowlistFixture(owner));
        
      // Deploy royalty Allowlist
      const royaltyAllowlistFactory = (await ethers.getContractFactory(
        "RoyaltyAllowlist"
      )) as RoyaltyAllowlist__factory;
      royaltyAllowlist = await royaltyAllowlistFactory.deploy(owner.address);
  
      // Deploy ERC721 contract
      const erc721PresetFactory = (await ethers.getContractFactory(
        "ImmutableERC721PermissionedMintable"
      )) as ImmutableERC721PermissionedMintable__factory;
  
      erc721 = await erc721PresetFactory.deploy(
        owner.address,
        name,
        symbol,
        baseURI,
        contractURI,
        royaltyAllowlist.address,
        royaltyRecipient.address,
        royalty,
      );
  
      // Set up roles
      await erc721.connect(owner).grantMinterRole(minter.address);
      await royaltyAllowlist.connect(owner).grantRegistrarRole(registrar.address);
    });

  describe("Contract Deployment", function () {
    it("Should set the admin role to the owner", async function () {
      const adminRole = await erc721.DEFAULT_ADMIN_ROLE();
      expect(await erc721.hasRole(adminRole, owner.address)).to.be.equal(true);
    });

    it("Should set the name and symbol of the collection", async function () {
      expect(await erc721.name()).to.equal(name);
      expect(await erc721.symbol()).to.equal(symbol);
    });

    it("Should set collection URI", async function () {
      expect(await erc721.contractURI()).to.equal(contractURI);
    });

    it("Should set base URI", async function () {
      expect(await erc721.baseURI()).to.equal(baseURI);
    });
  });

  describe("Minting and burning", function () {
    it("Should allow a member of the minter role to mint", async function () {
      await erc721.connect(minter).mint(user.address, 1);
      expect(await erc721.balanceOf(user.address)).to.equal(1);
      expect(await erc721.totalSupply()).to.equal(1);
    });

    it("Should revert when caller does not have minter role", async function () {
      await expect(erc721.connect(user).mint(user.address, 2)).to.be.revertedWith(
        "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000"
      );
    });

    it("Should allow safe minting of batch tokens", async function () {
      const mintRequests = [
        { to: user.address, tokenIds: [2, 3, 4] },
        { to: owner.address, tokenIds: [6, 7, 8] }
      ]
      await erc721.connect(minter).safeMintBatch(mintRequests);
      expect(await erc721.balanceOf(user.address)).to.equal(4);
      expect(await erc721.balanceOf(owner.address)).to.equal(3);
      expect(await erc721.totalSupply()).to.equal(7);
      expect(await erc721.ownerOf(2)).to.equal(user.address);
      expect(await erc721.ownerOf(3)).to.equal(user.address);
      expect(await erc721.ownerOf(4)).to.equal(user.address);
      expect(await erc721.ownerOf(6)).to.equal(owner.address);
      expect(await erc721.ownerOf(7)).to.equal(owner.address);
      expect(await erc721.ownerOf(8)).to.equal(owner.address);
    });


    it("Should allow owner or approved to burn a batch of tokens", async function () {
      expect(await erc721.balanceOf(user.address)).to.equal(4);
      await erc721.connect(user).burnBatch([1, 2]);
      expect(await erc721.balanceOf(user.address)).to.equal(2);
      expect(await erc721.totalSupply()).to.equal(5);
    });

    it("Should prevent not approved to burn a batch of tokens", async function () {
        await expect(erc721.connect(minter).burnBatch([3, 4])).to.be.revertedWith(
            "ERC721: caller is not token owner or approved"
        );
    });

    it("Should prevent minting burned tokens", async function () {
        const mintRequests = [
            { to: user.address, tokenIds: [1, 2] }
        ]
        await expect(erc721.connect(minter).safeMintBatch(mintRequests)).to.be.revertedWith(
            "ERC721: token already burned"
        );
    });
  });

  describe("Base URI and Token URI", function () {
    it("Should return a non-empty tokenURI when the base URI is set", async function () {
      const tokenId = 10
      await erc721.connect(minter).mint(user.address, tokenId);
      expect(await erc721.tokenURI(tokenId)).to.equal(`${baseURI}${tokenId}`);
    });

    it("Should revert with a burnt tokenId", async function () {
      const tokenId = 10
      await erc721.connect(user).burn(tokenId);
      await expect(erc721.tokenURI(tokenId)).to.be.revertedWith(
        "ERC721: invalid token ID"
      );
    });

    it("Should allow the default admin to update the base URI", async function () {
      const newBaseURI = "New Base URI";
      await erc721.connect(owner).setBaseURI(newBaseURI);
      expect(await erc721.baseURI()).to.equal(newBaseURI);
    });

    it("Should revert with a non-existent tokenId", async function () {
      await expect(erc721.tokenURI(1001)).to.be.revertedWith(
        "ERC721: invalid token ID"
      );
    });

    it("Should revert with a caller does not have admin role", async function () {
      await expect(
        erc721.connect(user).setBaseURI("New Base URI")
      ).to.be.revertedWith(
        "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });

    it("Should return an empty token URI when the base URI is not set", async function () {
      await erc721.setBaseURI("");
      const tokenId = 12
      await erc721.connect(minter).mint(user.address, tokenId);
      expect(await erc721.tokenURI(tokenId)).to.equal("");
    });
  });

  describe("Contract URI", function () {
    it("Should allow the default admin to update the contract URI", async function () {
      const newContractURI = "New Contract URI";
      await erc721.connect(owner).setContractURI(newContractURI);
      expect(await erc721.contractURI()).to.equal(newContractURI);
    });

    it("Should revert with a caller does not have admin role", async function () {
      await expect(
        erc721.connect(user).setContractURI("New Contract URI")
      ).to.be.revertedWith(
        "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });
  });

  describe("Supported Interfaces", function () {
    it("Should return true on supported interfaces", async function () {
      // ERC165
      expect(await erc721.supportsInterface("0x01ffc9a7")).to.equal(true);
      // ERC721
      expect(await erc721.supportsInterface("0x80ac58cd")).to.equal(true);
      // ERC721Metadata
      expect(await erc721.supportsInterface("0x5b5e139f")).to.equal(true);
    });
  });

  describe("Royalties", function () {
    it("Should set the correct royalties", async function () {
      const salePrice = ethers.utils.parseEther("1");
      const tokenInfo = await erc721.royaltyInfo(2, salePrice);

      expect(tokenInfo[0]).to.be.equal(royaltyRecipient.address);
      // (_salePrice * royalty.royaltyFraction) / _feeDenominator();
      // (1e18 * 2000) / 10000 = 2e17 (0.2 eth)
      expect(tokenInfo[1]).to.be.equal(ethers.utils.parseEther("0.2"));
    });
  });
  describe("Transfers", function () {

    it("Should allow users to transfer tokens using safeTransferFromBatch", async function () {
      // Mint tokens for testing transfers
      const mintRequests = [
        { to: minter.address, tokenIds: [51, 52, 53] },
        { to: user.address, tokenIds: [54, 55, 56] },
        { to: user2.address, tokenIds: [57, 58, 59] },
      ];

      await erc721.connect(minter).safeMintBatch(mintRequests);

      // Define transfer requests
      const transferRequests = [
        {
          from: minter.address,
          tos: [user.address, user.address, user2.address],
          tokenIds: [51, 52, 53],
        },
        { from: user.address, tos: [minter.address, minter.address], tokenIds: [54, 55] },
        { from: user2.address, tos: [minter.address], tokenIds: [57] },
      ];

      // Verify ownership before transfer
      expect(await erc721.ownerOf(51)).to.equal(minter.address);
      expect(await erc721.ownerOf(54)).to.equal(user.address);
      expect(await erc721.ownerOf(57)).to.equal(user2.address);

      // Perform transfers
      for (const transferReq of transferRequests) {
        await erc721
          .connect(ethers.provider.getSigner(transferReq.from))
          .safeTransferFromBatch(transferReq);
      }

      // Verify ownership after transfer
      expect(await erc721.ownerOf(51)).to.equal(user.address);
      expect(await erc721.ownerOf(52)).to.equal(user.address);
      expect(await erc721.ownerOf(53)).to.equal(user2.address);
      expect(await erc721.ownerOf(54)).to.equal(minter.address);
      expect(await erc721.ownerOf(55)).to.equal(minter.address);
      expect(await erc721.ownerOf(57)).to.equal(minter.address);
    });
  });
});

