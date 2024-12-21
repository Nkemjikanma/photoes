// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;
import {PhotoFactory721} from "./PhotoFactory721.sol";
import {PhotoFactory1155} from "apps/contract/src/PhotoFacotry1155.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PhotoFactoryEngine is ReentrancyGuard {
  error PhotoFactoryEngine__InvalidPhotoTokenId();
  error PhotoFactoryEngine__InvalidAmount();
  error PhotoFactoryEngine__MintFailed();
  error PhotoFactoryEngine__InvalidEditionSize();
  error PhotoFactoryEngine__TransactionFailed();

  PhotoFactory721 private factory721;
  PhotoFactory1155 private factory1155;

  // state variables
  address public contractOwner; // onwer of the contract
  uint256 private s_photoCounter; // counter of photos, but used as tokenId
  uint256 private s_itemsSold; // counter of items sold
  // PhotoItem[] public photoes; // array of counter
  address[] public minters;

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

  struct AiGeneratedVariant {
    string aiURI;
    string generationDate;
    bool minted;
  }

  mapping(uint256 => PhotoItem) public photoItem;
  mapping(uint256 => AiGeneratedVariant) public aiGeneratedVariant;

  event MintSuccessful(
    address indexed minter,
    uint256 indexed tokenId,
    string tokenURI,
    uint256 price,
    bool isERC721
  );

  constructor(address photoFactory721Address, address photoFactory1155Address) {
    factory721 = PhotoFactory721(photoFactory721Address);
    factory1155 = PhotoFactory1155(photoFactory1155Address);

    contractOwner = msg.sender; // change to dev wallet
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

    photoItem[s_photoCounter].tokenURI = _tokenURI;

    photoItem[s_photoCounter].buyer = msg.sender;

    if (_editionSize == 1) {
      try
        factory721.mintERC721(
          _tokenURI,
          _description,
          _photoName,
          _price,
          s_photoCounter
        )
      {
        photoItem[s_photoCounter] = PhotoItem(
          s_photoCounter,
          _photoName,
          1,
          _tokenURI,
          _description,
          msg.sender, // address of the buyer
          true,
          _price
        );

        minters.push(msg.sender);
        s_itemsSold++;
        emit MintSuccessful(
          msg.sender,
          s_photoCounter,
          _tokenURI,
          _price,
          true
        );
        s_photoCounter++;
      } catch {
        photoItem[s_photoCounter].minted = false;
        revert PhotoFactoryEngine__MintFailed();
      }
    }
  }

  function getPrice(uint _tokenId) public view returns (uint256) {
    return photoItem[_tokenId].price;
  }

  function createAiVariant(
    uint256 _tokenId,
    string memory _aiVariantURI
  ) public {
    if (photoItem[_tokenId].tokenId != _tokenId) {
      revert PhotoFactory721__InvalidPhotoTokenId();
    }
  }

  function verifyMint(uint256 tokenId) public view returns (bool) {
    if (_editionSize == 1) {
      return factory721.ownerOf(tokenId) == msg.sender;
    }
    return false;
  }

  function withdrawFunds() public onlyOwner {
    uint256 balance = address(this).balance;
    (bool success, ) = payable(owner()).call{value: balance}("");
    if (!success) {
      revert PhotoFactoryEngine__TransactionFailed();
    }
  }

  // Allow contract to receive ETH
  receive() external payable {
    withdrawFunds();
  }

  fallback() external payable {
    withdrawFunds();
  }

  function getPhotoCounter() public view returns (uint256) {
    return s_photoCounter;
  }

  function getItemsSold() public view returns (uint256) {
    return s_itemsSold;
  }

  function getMinters() public view returns (address[] memory) {
    return minters;
  }
}
