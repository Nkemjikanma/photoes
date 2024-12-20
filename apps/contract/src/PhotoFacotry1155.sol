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

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PhotoFactory1155 is
    ERC1155,
    Ownable,
    ERC1155Supply
{
    // Errors

    // state variables
    uint256 private s_tokenCounter; // keeps track of the numeber of tokens - can be called tokenId
    mapping(uint256 tokenId => string tokenURI) private s_tokenIdToTokenURI;

    address[] public minters; // address that have minted a token ?

    struct Photo {
        address creator;
        uint256 photoName;
        uint256 editionSize;
        string tokenURI;
        string description;
        uint256 minted;
        bool exists;
    }

    mapping(uint256 tokenId => Photo) public photoes; // mapping of tokenCounter/tokenId to photoes

    uint256 public constant DEFAULT_EDITION_SIZE = 100;

    // Events
    event OneOfOnePhotoMinted(
        address indexed onwer,
        uint256 indexed tokenId,
        string tokenURI
    );

    event MultipleOfOnePhotoMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string tokenURI,
        uint256 editionSize
    );

    constructor(
        address initialOwner
    ) ERC721("
    PhotoFactory", "PF") ERC1155("") Ownable(initialOwner) {
        s_tokenCounter = 0;
    }

    function mintERC721(string memory _tokenURI) public {
        s_tokenIdToTokenURI[s_tokenCounter] = _tokenURI;
        _safeMint(msg.sender, s_tokenCounter);
        _setTokenURI(s_tokenCounter, _tokenURI);
        s_tokenCounter++;

        //emit
        emit OneOfOnePhotoMinted(msg.sender, s_tokenCounter, tokenURI);
    }

    function mintERC1155(uint256 _mintAmount, string memory _tokenURI) public {
        // ensure that mint amount is not zero
        // ensere that the mint amount is less than 5
        // ensure that the number of mints is less than the edition size
        s_tokenIdToTokenURI[s_tokenCounter] = _tokenURI;
    }
}
