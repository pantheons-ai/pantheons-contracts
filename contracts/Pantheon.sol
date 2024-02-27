// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC404Instance} from "./ERC404Instance.sol";

contract Pantheon is Ownable {
    uint256 public id;
    string public uri;

    mapping(address => bool) private _whitelist;
    mapping(uint256 => ERC404Instance) public erc404Instances;

    event ERC404Created(uint256 indexed id, address indexed contractAddress);
    event WhitelistChanged(address indexed account, bool isWhitelisted);
    event URIUpdated(string newURI);

    constructor(string memory uri_) Ownable() {
        uri = uri_;
        _whitelist[msg.sender] = true;
    }

    function createERC404(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxTotalSupplyERC721_,
        address initialMintRecipient_
    ) external {
        ERC404Instance newERC404 = new ERC404Instance(name_, symbol_, decimals_, maxTotalSupplyERC721_, initialMintRecipient_, uri);
        erc404Instances[id] = newERC404;
        emit ERC404Created(id, address(newERC404));
        id++;
    }

    function _setURI(string memory newURI) external onlyOwner() {
        uri = newURI;
        emit URIUpdated(newURI);
    }

    function addToWhitelist(address account_) external onlyOwner {
        require(account_ != address(0), "Cannot add zero address to whitelist");
        _whitelist[account_] = true;
        emit WhitelistChanged(account_, true);
    }

    function removeFromWhitelist(address account_) external onlyOwner {
        require(account_ != address(0), "Cannot remove zero address from whitelist");
        _whitelist[account_] = false;
        emit WhitelistChanged(account_, false);
    }

    function isWhitelisted(address account_) public view returns (bool) {
        return _whitelist[account_];
    }

    // Add CIDs to the ERC404Instance associated with the given id
    function addCIDs(uint256 id_, address user, string[] memory cids) public {
        require(isWhitelisted(msg.sender), "Caller is not whitelisted");
        ERC404Instance instance = erc404Instances[id_];
        instance.addCIDs(user, cids);
    }

    // Get CIDs from the ERC404Instance associated with the given id
    function getCIDs(uint256 id_, address user) public view returns (string[] memory) {
        ERC404Instance instance = erc404Instances[id_];
        return instance.getCIDs(user);
    }

    // Get the contribution (number of CIDs) for a user from the ERC404Instance associated with the given id
    function getContribution(uint256 id_, address user) public view returns (uint256) {
        ERC404Instance instance = erc404Instances[id_];
        return instance.getContribution(user);
    }
}