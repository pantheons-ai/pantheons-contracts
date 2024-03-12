// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {SPG} from "@story-protocol/protocol-periphery/contracts/lib/SPG.sol";
import {IStoryProtocolToken} from "@story-protocol/protocol-periphery/contracts/interfaces/IStoryProtocolToken.sol";

contract StoryProtocolToken is Ownable, ERC721, IStoryProtocolToken {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to SPG.MintSettings
    mapping(uint256 => SPG.MintSettings) private _mintSettings;

    // Used for generating unique token IDs
    uint256 private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender){
        _name = name_;
        _symbol = symbol_;
        _tokenIdCounter = 0;
    }

    /// @notice Mints a new token, optionally providing additional metadata.
    function mint(address to, bytes memory) external override returns (uint256) {
        _tokenIdCounter += 1;
        uint256 newTokenId = _tokenIdCounter;

        _mint(to, newTokenId);
        return newTokenId;
    }

    /// @notice Configures the minting settings for an ongoing Story Protocol mint.
    function configureMint(address spg, SPG.MintSettings calldata mintSettings) external override onlyOwner {
        require(spg != address(0), "SPG address cannot be the zero address");
        // Assuming each token has unique settings, this could be adjusted based on your requirements
        _mintSettings[_tokenIdCounter] = mintSettings;
    }
}
