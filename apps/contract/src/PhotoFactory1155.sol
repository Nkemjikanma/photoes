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
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/*
 * @title PhotoFactory1155
 * @author Nkemjika
 * @notice This contract handles ERC11155 photo minting on Phtoes
 * @dev Implements ERC1155, ERC1155SUPPLY, Ownable, ERC2981
 */

contract PhotoFactory1155 is ERC1155, Ownable, ERC1155Supply, ERC2981 {
    // Errors
    error Photofactory1155__maxsupplyexceeded();
    error PhotoFactory1155__InvalidAddress();

    // state variables
    uint256 public constant DEFAULT_EDITION_SIZE = 20;
    uint96 public constant ROYALTY_FEE_NUMERATOR = 500; // 5%

    // Events
    event MultipleTokenMinted(uint256 indexed id, uint256 amount);

    event BatchMinted(address indexed to, uint256[] ids, uint256[] amounts);

    constructor(string memory _nftName, address initialOwner) ERC1155(_nftName) Ownable(initialOwner) {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) public onlyOwner {
        if (_to == address(0)) revert PhotoFactory1155__InvalidAddress();
        if (totalSupply(_tokenId) + _amount > DEFAULT_EDITION_SIZE) {
            revert Photofactory1155__maxsupplyexceeded();
        }

        _mint(_to, _tokenId, _amount, _data);
        _setTokenRoyalty(_tokenId, owner(), ROYALTY_FEE_NUMERATOR);

        emit MultipleTokenMinted(_tokenId, _amount);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        if (to == address(0)) revert PhotoFactory1155__InvalidAddress();
        require(ids.length == amounts.length, "Length mismatch");
        _mintBatch(to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _setTokenRoyalty(ids[i], owner(), ROYALTY_FEE_NUMERATOR);
        }

        emit BatchMinted(to, amounts, amounts);
    }

    function getTokenSupply(uint256 id) public view returns (uint256) {
        return totalSupply(id);
    }

    function withdrawERC1155() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }

    function transferERC1155(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _safeTransferFrom(from, to, id, amount, data);
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

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
