// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IPhotoFactoryEngine {
  struct PhotoItem {
    uint256 tokenId;
    string photoName;
    uint256 editionSize;
    string tokenURI;
    string description;
    address owner; // address of the buyer
    bool minted;
    bool purchased;
    uint256 price; // price of the item
    uint256 aiVariantTokenId; // AI variant tokenId for this photo
  }

  struct MultiplePhotoItems {
    uint256 tokenId;
    string photoName;
    uint256 editionSize;
    string tokenURI;
    string description;
    address[] owners; // address of the buyers
    uint256 price; // price of the item
    bool minted;
    uint256 totalPurchased; // Track total minted for this edition
    uint256[] aiVariantTokenIds; // Array of all AI variant tokenIds for this photo
  }

  struct AiGeneratedVariant {
    string aiURI;
    uint256 originalImage;
    string description; // description of the photo for ai variant
    uint256 variantId;
    uint256 generationDate;
    bool minted;
  }

  struct UserAiVariant {
    uint256 aiTokenId;
    address owner;
    uint256 originalPhotoTokenId;
  }

  // track ownership
  struct EditionOwnership {
    uint256 copiesOwned;
    uint256[] aiVariantIds;
    bool canMintAi;
  }

  // Function declarations
  function mint(
    string memory tokenURI,
    string memory description,
    string memory photoName,
    uint256 price,
    uint256 editionSize
  ) external;

  function purchase(
    uint256 tokenId,
    uint256 quantity,
    bool isUSDC
  ) external payable;

  function getMultiplePhotoItems(
    uint256 tokenId
  ) external view returns (MultiplePhotoItems memory);

  function getEditionOwnership(
    uint256 _tokenId,
    address _owner
  ) external view returns (EditionOwnership memory);

  function getUserEditionCount(
    address _user,
    uint256 _tokenId
  ) external view returns (uint256);

  function getPhotoItem(
    uint256 tokenId
  ) external view returns (PhotoItem memory);
}
