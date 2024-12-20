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

    struct Photo {
        string photoName;
        uint256 editionSize;
        string tokenURI;
        string description;
        bool minted;
    }

    // Events
    event OneOfOnePhotoMinted(
        address indexed onwer,
        uint256 indexed tokenId,
        string tokenURI
    );

    constructor(
        address initialOwner
    ) ERC721("PhotoFactory", "PF") Ownable(initialOwner) {}

    function mintERC721(
        string memory _tokenURI,
        string memory _description,
        string memory _photoName
    ) public {
        s_tokenIdToTokenURI[s_photoCounter] = _tokenURI;

        photoes[s_photoCounter] = Photo(
            _photoName,
            1,
            _tokenURI,
            _description,
            true
        );

        minters.push(msg.sender);

        _safeMint(msg.sender, s_photoCounter);
        _setTokenURI(s_photoCounter, _tokenURI);
        s_photoCounter++;

        //emit
        emit OneOfOnePhotoMinted(msg.sender, s_photoCounter, _tokenURI);
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
