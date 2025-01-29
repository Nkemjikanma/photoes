// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IPhotoFactoryEngine {
  enum EditionType {
    Single, // ERC721
    Multiple // ERC1155
  }

  enum CollectionCategory {
    Photography,
    Art,
    Nature,
    Portrait,
    Abstract,
    Other
  }

  struct CollectionMetadata {
    string coverImageURI;
    string featuredPhotoURI;
    string[] tags;
    mapping(string => string) customAttributes;
  }

  struct Collection {
    uint256 collectionId;
    string name;
    string description;
    address creator;
    uint256 createdAt;
    uint256 basePrice;
    CollectionCategory category;
    CollectionMetadata metadata;
    uint256[] photoIds; // All photoids in this collection
    mapping(uint256 => Photo) photos; // Track all photos in this collection
  }

  struct Photo {
    uint256 tokenId;
    string name;
    string description;
    string tokenURI;
    EditionType editionType;
    uint256 editionSize;
    uint256 price;
    uint256 totalMinted;
    bool isActive;
    address creator;
    uint256 createdAt;
    uint256 collectionId; // 0 if not part of collection
    uint256[] aiVariantIds; // AI variants generated for this photo
  }

  // Track ownership of photos
  struct PhotoOwnership {
    uint256 photoId;
    address owner;
    uint256 quantity; // 1 for Single, can be more for Multiple
    uint256[] aiVariantIds; // AI variants owned by this owner
    uint256 purchaseDate;
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

  function getEditionOwnership(
    uint256 _tokenId,
    address _owner
  ) external view returns (EditionOwnership memory);

  function getUserEditionCount(
    address _user,
    uint256 _tokenId
  ) external view returns (uint256);

  function getPhotoItem(uint256 tokenId) external view returns (Photo memory);
}
