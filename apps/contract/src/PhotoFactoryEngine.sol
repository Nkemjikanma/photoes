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

/*
 * @title PhotoFactoryEngine
 * @author Nkemjika
 * @notice This contract is the handler for PhotoFactory721 and PhotoFactory1155 - automatically deciding what contract to call for mints.
 * @dev Implements ERC1155, ERC1155SUPPLY, Ownable
 */
contract PhotoFactoryEngine is ReentrancyGuard, Ownable {
    error PhotoFactoryEngine__InvalidPhotoTokenId();
    error PhotoFactoryEngine__InvalidAmount();
    error PhotoFactoryEngine__MintFailed();
    error PhotoFactoryEngine__InvalidEditionSize();
    error PhotoFactoryEngine__TransactionFailed();
    error PhotoFactoryEngine_InvalidPhotoTokenId();
    error PhotoFactoryEngine__InvalidPrice();
    error PhotoFactoryEngine__InvalidOwner();
    error PhotoFactoryEngine__AlreadyBought();

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
        address seller; // who is selling
        address owner; // address of the buyer
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

    modifier onlyPhotoOwner(uint256 _tokenId) {
        if (msg.sender != photoItem[_tokenId].owner) {
            revert PhotoFactoryEngine__InvalidOwner();
        }
        _;
    }

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
        // if (msg.value == 0) {
        //   revert PhotoFactoryEngine__InvalidAmount();
        // }
        if (_editionSize < 1) {
            revert PhotoFactoryEngine__InvalidEditionSize();
        }

        // if (_exists(s_photoCounter)) {
        //   revert PhotoFactoryEngine__InvalidPhotoTokenId();
        // }
        s_photoCounter += 1; // increment the counter
        uint256 tokenId = s_photoCounter;

        photoItem[s_photoCounter] = PhotoItem(
            tokenId,
            _photoName,
            _editionSize,
            _tokenURI,
            _description,
            payable(owner()),
            payable(owner()), // address of the buyer
            false,
            _price
        );

        if (_editionSize == 1) {
            try factory721.mintERC721(_tokenURI, tokenId) {
                photoItem[tokenId].minted = true;

                emit MintSuccessful(msg.sender, tokenId, _tokenURI, _price, true);
            } catch {
                photoItem[s_photoCounter].minted = false;
                revert PhotoFactoryEngine__MintFailed();
            }
        } else {
            try factory1155.mint(msg.sender, tokenId, _editionSize, "") {
                photoItem[tokenId].minted = true;
                emit MintSuccessful(msg.sender, tokenId, _tokenURI, _price, false);
            } catch {
                photoItem[tokenId].minted = false;
                revert PhotoFactoryEngine__MintFailed();
            }
        }
    }

    function purchase(uint256 _tokenId, uint256 _price) public payable nonReentrant {
        PhotoItem storage item = photoItem[_tokenId];

        if (item.minted == false) {
            revert PhotoFactoryEngine_InvalidPhotoTokenId();
        }

        if (item.owner == msg.sender) {
            revert PhotoFactoryEngine__AlreadyBought();
        }

        if (item.seller == msg.sender) {
            revert PhotoFactoryEngine__AlreadyBought();
        }

        if (item.price != _price) {
            revert PhotoFactoryEngine__InvalidPrice();
        }

        // transfer ownership of the token to the buyer

        if (item.editionSize == 1) {
            factory721.transferERC721(item.owner, msg.sender, _tokenId);
        } else {
            factory1155.transferERC1155(item.owner, msg.sender, _tokenId, 1, "");
        }

        item.owner = msg.sender;
        item.seller = msg.sender;

        // Generate AI variant
        // generateAiVariant(tokenId);

        // Transfer funds to the owner
        (bool success,) = payable(owner()).call{value: msg.value}("");
        if (!success) {
            revert PhotoFactoryEngine__TransactionFailed();
        }

        buyers.push(msg.sender);
        s_itemsSold++;
    }

    // function generateAiVariant(uint256 tokenId) internal {
    //   // Generate AI variant URI (this is a placeholder, replace with actual AI generation logic)
    //   string memory aiURI = string(
    //     abi.encodePacked(photoItem[tokenId].tokenURI, "-ai")
    //   );

    //   aiGeneratedVariant[tokenId] = AiGeneratedVariant(
    //     aiURI,
    //     block.timestamp,
    //     true
    //   );
    // }

    function updatePrice(uint256 _tokenId) public payable onlyPhotoOwner(_tokenId) {
        photoItem[_tokenId].price = msg.value;
    }

    function getPrice(uint256 _tokenId) public view returns (uint256) {
        return photoItem[_tokenId].price;
    }

    // TODO: implement reselling
    function resellPhoto(uint256 _tokenId, uint256 _price) public payable onlyPhotoOwner(_tokenId) {
        PhotoItem storage item = photoItem[_tokenId];
        item.price = _price;
        item.seller = payable(msg.sender);
        item.owner = payable(owner());
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

        (bool success,) = payable(owner()).call{value: balance}("");
        if (!success) {
            revert PhotoFactoryEngine__TransactionFailed();
        }
    }

    // Allow contract to receive ETH
    receive() external payable {}

    fallback() external payable {}

    function _exists(uint256 tokenId) private view returns (bool) {
        return photoItem[tokenId].minted;
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
