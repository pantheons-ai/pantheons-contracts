// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC404Instance} from "./ERC404Instance.sol";
import {IStoryProtocolGateway} from "@story-protocol/protocol-periphery/contracts/interfaces/IStoryProtocolGateway.sol";
import {SPG} from "@story-protocol/protocol-periphery/contracts/lib/SPG.sol";
import {Metadata} from "@story-protocol/protocol-periphery/contracts/lib/Metadata.sol";
import {StoryProtocolToken} from "./ERC721.sol";

interface IERC1271 {
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
}

contract Pantheon is Ownable, IERC165, IERC1271, IERC721Receiver, IERC1155Receiver {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    uint256 public id;
    string public uri;
    uint256 public immutable POLICY_ID;
    IStoryProtocolGateway public spg;
    address public immutable NFT_ADDRESS;

    mapping(address => bool) private _whitelist;
    mapping(uint256 => ERC404Instance) public erc404Instances;

    event ERC404Created(uint256 indexed erc404Id, address indexed contractAddress, uint256 indexed tokenId, address ipId);
    event WhitelistChanged(address indexed account, bool isWhitelisted);
    event URIUpdated(string newURI);

    constructor(string memory uri_, address spg_, uint256 policyId_) Ownable() {
        uri = uri_;
        _whitelist[msg.sender] = true;
        spg = IStoryProtocolGateway(spg_);
        StoryProtocolToken spgNFT = new StoryProtocolToken("spgNFT", "SNFT");
        NFT_ADDRESS = address(spgNFT);
        POLICY_ID = policyId_;
    }

    function createERC404(
        string calldata name_,
        string calldata erc404Symbol_,
        uint8 erc404Decimals_,
        uint256 maxTotalSupplyERC721_,
        address initialMintRecipient_,
        string calldata nftDescription,
        string calldata nftUrl,
        string calldata nftImage,
        string[] calldata nftAttributeKeys,
        string[] calldata nftAttributeValues,
        string calldata ipName_,
        bytes32 ipHash,
        string calldata ipUrl,
        string[] calldata ipAttributeKeys,
        string[] calldata ipAttributeValues
    ) external {
        erc404Instances[id] = new ERC404Instance(name_, erc404Symbol_, erc404Decimals_, maxTotalSupplyERC721_, initialMintRecipient_, uri);
        require(nftAttributeKeys.length == nftAttributeValues.length, "NFT attributes length mismatch");
        require(ipAttributeKeys.length == ipAttributeValues.length, "IP attributes length mismatch");

        // 构建NFT属性数组
        Metadata.Attribute[] memory nftAttributes = new Metadata.Attribute[](nftAttributeKeys.length);
        for (uint i = 0; i < nftAttributeKeys.length; i++) {
            nftAttributes[i] = Metadata.Attribute({
                key: nftAttributeKeys[i],
                value: nftAttributeValues[i]
            });
        }

        // 构建IP属性数组
        Metadata.Attribute[] memory ipAttributes = new Metadata.Attribute[](ipAttributeKeys.length);
        for (uint i = 0; i < ipAttributeKeys.length; i++) {
            ipAttributes[i] = Metadata.Attribute({
                key: ipAttributeKeys[i],
                value: ipAttributeValues[i]
            });
        }

        // 编码NFT元数据
        bytes memory nftMetadata = abi.encode(
            name_,
            nftDescription,
            nftUrl,
            nftImage,
            nftAttributes
        );
        
        // 编码IP元数据
        Metadata.IPMetadata memory ipMetadata = Metadata.IPMetadata({
            name: ipName_,
            hash: ipHash,
            url: ipUrl,
            customMetadata: ipAttributes
        });

        SPG.Signature memory signature = SPG.Signature({
            signer: address(this),
            deadline: block.timestamp + 1000,
            signature: ""
        });
        
        try spg.mintAndRegisterIpWithSig(
            POLICY_ID,
            NFT_ADDRESS,
            nftMetadata,
            ipMetadata,
            signature
        ) returns (uint256 _tokenId, address _ipId) {
            emit ERC404Created(id, address(erc404Instances[id]), _tokenId, _ipId);
        } catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory lowLevelData) {
            revert("mintAndRegisterIpWithSig failed without a reason");
        }
        id++;
    }

    // function register(
    //     string calldata nftName,
    //     string calldata nftDescription,
    //     string calldata nftUrl,
    //     string calldata nftImage,
    //     string[] calldata nftAttributeKeys,
    //     string[] calldata nftAttributeValues,
    //     string calldata ipName,
    //     bytes32 ipHash,
    //     string calldata ipUrl,
    //     string[] calldata ipAttributeKeys,
    //     string[] calldata ipAttributeValues
    // ) internal returns (uint256 tokenId, address ipId) {
    //     require(nftAttributeKeys.length == nftAttributeValues.length, "NFT attributes length mismatch");
    //     require(ipAttributeKeys.length == ipAttributeValues.length, "IP attributes length mismatch");

    //     // 构建NFT属性数组
    //     Metadata.Attribute[] memory nftAttributes = new Metadata.Attribute[](nftAttributeKeys.length);
    //     for (uint i = 0; i < nftAttributeKeys.length; i++) {
    //         nftAttributes[i] = Metadata.Attribute({
    //             key: nftAttributeKeys[i],
    //             value: nftAttributeValues[i]
    //         });
    //     }

    //     // 构建IP属性数组
    //     Metadata.Attribute[] memory ipAttributes = new Metadata.Attribute[](ipAttributeKeys.length);
    //     for (uint i = 0; i < ipAttributeKeys.length; i++) {
    //         ipAttributes[i] = Metadata.Attribute({
    //             key: ipAttributeKeys[i],
    //             value: ipAttributeValues[i]
    //         });
    //     }

    //     // 编码NFT元数据
    //     bytes memory nftMetadata = abi.encode(
    //         nftName,
    //         nftDescription,
    //         nftUrl,
    //         nftImage,
    //         nftAttributes
    //     );
        
    //     // 编码IP元数据
    //     Metadata.IPMetadata memory ipMetadata = Metadata.IPMetadata({
    //         name: ipName,
    //         hash: ipHash,
    //         url: ipUrl,
    //         customMetadata: ipAttributes
    //     });

    //     SPG.Signature memory signature = SPG.Signature({
    //         signer: address(this),
    //         deadline: block.timestamp + 1000,
    //         signature: ""
    //     });
        
    //     try spg.mintAndRegisterIpWithSig(
    //         POLICY_ID,
    //         NFT_ADDRESS,
    //         nftMetadata,
    //         ipMetadata,
    //         signature
    //     ) returns (uint256 _tokenId, address _ipId) {
    //         // 如果调用成功，返回结果
    //         return (_tokenId, _ipId);
    //     } catch Error(string memory reason) {
    //         // 如果调用失败，并且有错误信息，将错误信息作为字符串抛出
    //         revert(reason);
    //     } catch (bytes memory /* lowLevelData */) {
    //         // 如果调用失败，但没有提供错误信息，抛出通用错误
    //         revert("mintAndRegisterIpWithSig failed without a reason");
    //     }
    // }

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

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view override returns (bytes4) {
        return MAGICVALUE;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId);
    }
    /// @inheritdoc IERC721Receiver
    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}