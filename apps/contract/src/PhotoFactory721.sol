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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/*
 * @title PhotoFactory721
 * @author Nkemjika
 * @notice This contract handles ERC721 photo minting for Phtoes
 * @dev Implements ERC721, ERC721URIStorage,
 */

contract PhotoFactory721 is ERC721, ERC721URIStorage, Ownable, ERC2981 {
    // Errors
    error PhotoFactory721__InvalidURI(); //tokenURI is invalid
    error PhotoFactory721__InvalidPrice(); // price is invalid

    // state variables
    uint96 public constant ROYALTY_FEE_NUMERATOR = 500; // 5%

    // Events
    event OneOfOnePhotoMinted(uint256 indexed tokenId, string tokenURI);

    // Modifiers

    constructor(address initialOwner) ERC721("PhotoFactory", "PF") Ownable(initialOwner) {}

    function mintERC721(string memory _tokenURI, uint256 _tokenId) public onlyOwner {
        if (bytes(_tokenURI).length == 0) revert PhotoFactory721__InvalidURI();
        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _setTokenRoyalty(_tokenId, owner(), ROYALTY_FEE_NUMERATOR);
        //emit
        emit OneOfOnePhotoMinted(_tokenId, _tokenURI);
    }

    function withdrawERC721() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }

    // Added required override functions
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
