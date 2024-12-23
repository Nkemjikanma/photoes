// SPDX-License-Identifier: MIT

// Layout of contract
// version
// imports
// errors
// interfaces, libraries, contracts
// type declarations
// state variables
// events
// modifiers
// Functions

// Layout of Functions
// Constructor
// Recieve function(if exists)
// fallback function(if exists)
// External
// Public
// Internal
// Private
// View & Pure functions

pragma solidity ^0.8.27;

import {PhotoFactory721} from "./PhotoFactory721.sol";
import {PhotoFactory1155} from "./PhotoFacotry1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/*
 * @title PhotoFactoryEngine
 * @author Nkemjika
 * @notice This contract is the handler for PhotoFactory721 and PhotoFactory1155 - automatically deciding what contract to call for mints.
 * @dev Implements ERC1155, ERC1155SUPPLY, Ownable, ERC2981
 */
contract PhotoFactoryEngine is ERC2981, ReentrancyGuard, Ownable {
    error PhotoFactoryEngine__InvalidPhotoTokenId();
    error PhotoFactoryEngine__InvalidAmount();
    error PhotoFactoryEngine__MintFailed();
    error PhotoFactoryEngine__InvalidEditionSize();
    error PhotoFactoryEngine__TransactionFailed();

    PhotoFactory721 private factory721;
    PhotoFactory1155 private factory1155;

    // state variables
    uint96 public constant ROYALTY_FEE_NUMERATOR = 500; // 5%

    uint256 private s_photoCounter; // counter of photos, but used as tokenId
    uint256 private s_itemsSold; // counter of items sold

    address[] public buyers;

    struct PhotoItem {
        uint256 tokenId;
        string photoName;
        uint256 editionSize;
        string tokenURI;
        string description;
        address buyer; // address of the buyer
        bool minted;
        uint256 price; // price of the item
    }

    struct MultiEditionPhotoItem {
        uint256 tokenId;
        string photoName;
        uint256 editionSize;
        string tokenURI;
        string description;
        address buyer; // address of the buyer
        bool minted;
        uint256 price; // price of the item
    }

    struct AiGeneratedVariant {
        string aiURI;
        string generationDate;
        bool minted;
    }

    mapping(uint256 => PhotoItem) public photoItem;
    mapping(uint256 => AiGeneratedVariant) public aiGeneratedVariant;

    event MintSuccessful(
        address indexed minter, uint256 indexed tokenId, string tokenURI, uint256 price, bool isERC721
    );

    event RoyaltyUpdated(uint256 indexed tokenId, address receiver, uint96 feeNumerator);

    // event MultipleOfOnePhotoMinted(
    //   address indexed owner,
    //   uint256 indexed tokenId,
    //   string tokenURI,
    //   uint256 editionSize
    // );

    constructor(address photoFactory721Address, address photoFactory1155Address, address initialOwner)
        Ownable(initialOwner)
    {
        factory721 = PhotoFactory721(photoFactory721Address);
        factory1155 = PhotoFactory1155(photoFactory1155Address);

        s_photoCounter = 0;
        s_itemsSold = 0;
    }

    function mint(
        string memory _tokenURI,
        string memory _description,
        string memory _photoName,
        uint256 _price,
        uint256 _editionSize
    ) public payable nonReentrant {
        if (msg.value == 0) {
            revert PhotoFactoryEngine__InvalidAmount();
        }
        if (_editionSize < 1) {
            revert PhotoFactoryEngine__InvalidEditionSize();
        }

        uint256 tokenId = s_photoCounter;

        // Todo, implement check to see if tokenId already exists or token Id is 0
        if (tokenId == 0) {
            revert PhotoFactoryEngine__InvalidPhotoTokenId();
        }
        if (_exists(tokenId)) {
            revert PhotoFactoryEngine__InvalidPhotoTokenId();
        }

        photoItem[s_photoCounter] = PhotoItem(
            tokenId,
            _photoName,
            _editionSize,
            _tokenURI,
            _description,
            msg.sender, // address of the buyer
            false,
            _price
        );

        if (_editionSize == 1) {
            try factory721.mintERC721(_tokenURI, tokenId) {
                photoItem[tokenId].minted = true;

                buyers.push(msg.sender);
                s_itemsSold++;
                emit MintSuccessful(msg.sender, s_photoCounter, _tokenURI, _price, true);
                s_photoCounter++;
            } catch {
                photoItem[s_photoCounter].minted = false;
                revert PhotoFactoryEngine__MintFailed();
            }
        } else {
            try factory1155.mint(msg.sender, tokenId, _editionSize, "") {
                photoItem[tokenId].minted = true;
                buyers.push(msg.sender);
                s_itemsSold++;
                emit MintSuccessful(msg.sender, tokenId, _tokenURI, _price, false);
                s_photoCounter++;
            } catch {
                photoItem[tokenId].minted = false;
                revert PhotoFactoryEngine__MintFailed();
            }
        }
    }

    function getPrice(uint256 _tokenId) public view returns (uint256) {
        return photoItem[_tokenId].price;
    }

    // function createAiVariant(
    //   uint256 _tokenId,
    //   string memory _aiVariantURI
    // ) public {
    //   if (photoItem[_tokenId].tokenId != _tokenId) {
    //     revert PhotoFactoryEngine__InvalidPhotoTokenId();
    //   }

    //   aiGeneratedVariant[_tokenId] = AiGeneratedVariant(
    //     _aiVariantURI,
    //     block.timestamp,
    //     false
    //   );
    // }

    function verifyMint(uint256 tokenId) public view returns (bool) {
        return photoItem[tokenId].minted;
    }

    // Verify how to withdraw funds from all contracts
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;

        factory721.withdrawERC721();
        factory1155.withdrawERC1155();

        (bool success,) = payable(owner()).call{value: balance}("");
        if (!success) {
            revert PhotoFactoryEngine__TransactionFailed();
        }
    }

    function setTokenRoyalty(uint256 tokenId) internal {
        _setTokenRoyalty(tokenId, owner(), ROYALTY_FEE_NUMERATOR);
    }

    function updateRoyaltyInfo(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function getRoyaltyInfo(uint256 tokenId, uint256 salePrice) public view returns (address, uint256) {
        return royaltyInfo(tokenId, salePrice);
    }

    // Allow contract to receive ETH
    receive() external payable {}

    fallback() external payable {}

    function _exists(uint256 tokenId) private view returns (bool) {
        bool doesExist = photoItem[tokenId].minted;

        return doesExist;
    }

    function getPhotoCounter() public view returns (uint256) {
        return s_photoCounter;
    }

    function getItemsSold() public view returns (uint256) {
        return s_itemsSold;
    }

    function getBuyers() public view returns (address[] memory) {
        return buyers;
    }
}
