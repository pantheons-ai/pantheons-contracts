// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC404} from "./ERC404.sol";

contract ERC404Instance is Ownable, ERC404 {
    string public uri;
    mapping(address => string[]) private userCIDs;

    // Event to log the addition of CIDs
    event CIDsAdded(address indexed user, string[] cids);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxTotalSupplyERC721_,
        address initialMintRecipient_,
        string memory uri_
    ) ERC404(name_, symbol_, decimals_) Ownable() {
        uri = uri_;
        _setERC721TransferExempt(initialMintRecipient_, true);
        if (maxTotalSupplyERC721_ > 0) {
            _mintERC20(initialMintRecipient_, maxTotalSupplyERC721_ * units);
        }
    }

    function tokenURI(uint256 id_) public view override returns (string memory) {
        return string.concat(uri, Strings.toString(id_));
    }

    function setERC721TransferExempt(
        address account_,
        bool value_
    ) external onlyOwner {
        _setERC721TransferExempt(account_, value_);
    }

    function addCIDs(address user, string[] memory cids) public onlyOwner {
        for (uint256 i = 0; i < cids.length; i++) {
            userCIDs[user].push(cids[i]);
        }
        // Mint ERC20 tokens to the user based on the number of CIDs added
        _mintERC20(user, cids.length * units);

        // Emit the event after adding CIDs
        emit CIDsAdded(user, cids);
    }

    function getCIDs(address user) public view returns (string[] memory) {
        return userCIDs[user];
    }

    function getContribution(address user) public view returns (uint256) {
        return userCIDs[user].length;
    }
}