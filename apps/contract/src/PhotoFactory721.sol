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
  }

  function mintERC721(
    string memory _tokenURI,
    uint256 _price,
    uint256 _tokenId
  ) public payable {
    if (msg.value != _price) {
      revert PhotoFactory721__InvalidPrice();
    }

    _safeMint(msg.sender, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);

    //emit
    emit OneOfOnePhotoMinted(msg.sender, _tokenId, _tokenURI, _price);

    //TODO: create ai generated photo
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
}
