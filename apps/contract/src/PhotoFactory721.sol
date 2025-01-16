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
    error PhotoFactory__LocalMintFailed();
    error PhotoFactory721__InvalidOwner();

    // state variables
    uint96 public constant ROYALTY_FEE_NUMERATOR = 500; // 5%

    // Events
    event OneOfOnePhotoMinted(uint256 indexed tokenId, string tokenURI);

    // Modifiers

    constructor(string memory _nftName, address initialOwner) ERC721(_nftName, "") Ownable(initialOwner) {
        _setDefaultRoyalty(owner(), ROYALTY_FEE_NUMERATOR);
    }

    function mintERC721(string memory _tokenURI, uint256 _tokenId) public onlyOwner {
        if (bytes(_tokenURI).length == 0 || keccak256(bytes(_tokenURI)) == keccak256(bytes(" "))) {
            revert PhotoFactory721__InvalidURI();
        }

        if (owner() == address(0)) {
            revert PhotoFactory721__InvalidOwner();
        }

        _safeMint(owner(), _tokenId);
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

    function transferERC721(address from, address to, uint256 tokenId) public onlyOwner {
        _transfer(from, to, tokenId);
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
