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

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PhotoFactory721 is ERC721, ERC721URIStorage, Ownable {
  // Errors
  error PhotoFactory721__InvalidPhotoTokenId(); // tokenId is invalid
  error PhotoFactory721__InvalidPrice(); // price is invalid

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

  // Events
  event OneOfOnePhotoMinted(
    address indexed onwer,
    uint256 indexed tokenId,
    string tokenURI,
    uint256 price
  );

  // Modifiers

  constructor(
    address initialOwner
  ) ERC721("PhotoFactory", "PF") Ownable(initialOwner) {
    contractOwner = msg.sender; // change to dev wallet
    s_photoCounter = 0;
    s_itemsSold = 0;
  }

  function mintERC721(
    string memory _tokenURI,
    string memory _description,
    string memory _photoName,
    uint256 _price
  ) public payable {
    if (msg.value != _price) {
      revert PhotoFactory721__InvalidPrice();
    }

    photoItem[s_photoCounter].tokenURI = _tokenURI;

    photoItem[s_photoCounter].buyer = msg.sender;

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

    _safeMint(msg.sender, s_photoCounter);
    _setTokenURI(s_photoCounter, _tokenURI);

    //emit
    emit OneOfOnePhotoMinted(msg.sender, s_photoCounter, _tokenURI, _price);

    //TODO: create ai generated photo
    minters.push(msg.sender);
    s_photoCounter++;
  }

  // Added required override functions
  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
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
}
