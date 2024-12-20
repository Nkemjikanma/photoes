// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {PhotoFactory721} from "./PhotoFactory721.sol";
import {PhotoFactory1155} from "apps/contract/src/PhotoFacotry1155.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PhotoFactoryEngine is ReentrancyGuard {
    PhotoFactory721 private factory721;
    PhotoFactory1155 private factory1155;

    // state variables
    uint256 private s_photoCounter; // keeps track of the numeber of tokens - can be called tokenId
    mapping(uint256 tokenId => string tokenURI) private s_tokenIdToTokenURI;
    address[] public minters; // address that have minted a token ?

    mapping(uint256 tokenId => Photo) public photoes; // mapping of tokenCounter/tokenId to photoes

    constructor(
        address photoFactory721Address,
        address photoFactory1155Address
    ) {
        factory721 = PhotoFactory(photoFactory721Address);
        factory1155 = PhotoFactory(photoFactory1155Address);

        s_photoCounter = 0;
    }
}
