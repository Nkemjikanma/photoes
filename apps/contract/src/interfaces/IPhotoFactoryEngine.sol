// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IPhotoFactoryEngine {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event PhotoCreated(
        uint256 indexed tokenId, EditionType editionType, uint256 editionSize, uint256 indexed collectionId
    );

    event CollectionCreated(uint256 indexed collectionId, string name, address indexed creator, uint256 photoCount);

    event CollectionMetadataUpdated(uint256 indexed collectionId, string coverImageURI, string featuredPhotoURI);

    event PhotoAddedToCollection(uint256 indexed collectionId, uint256 indexed photoId);

    event MintSuccessful(
        address indexed minter, uint256 indexed tokenId, string tokenURI, uint256 price, bool isERC721
    );

    event PhotoPurchased(uint256 indexed tokenId, address indexed buyer, uint256 quantity, uint256 price);

    event AIGenerationRequested(uint256 indexed tokenId, bytes32 requestId);
    event AIGenerationCompleted(uint256 indexed tokenId, uint256 indexed aiVariantId, string aiURI);
    event AIGenerationFailed(uint256 indexed tokenId, bytes error);
    event AIVariantMinted(uint256 indexed originalTokenId, uint256 indexed aiTokenId);

    event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    event FundsWithdrawn(address indexed receiver, uint256 ethAmount, uint256 usdcAmount);

    /*//////////////////////////////////////////////////////////////
                               STRUCTS AND ENUMS
    //////////////////////////////////////////////////////////////*/
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

    struct CollectionCreationParams {
        string name;
        string description;
        CollectionCategory[] categories;
        PhotoCreationParams[] photoCreationParams;
        string[] tags;
        string coverImageURI;
        string featuredPhotoURI;
    }

    struct Collection {
        uint256 collectionId;
        string name;
        string description;
        address creator;
        uint256 createdAt;
        CollectionCategory[] category;
        CollectionMetadata metadata;
        uint256[] photoIds; // All photoids in this collection
    }

    struct PhotoCreationParams {
        string name;
        string description;
        string tokenURI;
        uint32 editionSize;
        uint96 price;
    }

    struct MintPhotoParams {
        string name;
        string description;
        string tokenURI;
        EditionType editionType;
        uint32 editionSize;
        uint96 price;
        uint256 collectionId;
    }

    struct Photo {
        uint256 tokenId;
        string name;
        string description;
        string tokenURI;
        EditionType editionType;
        uint32 editionSize;
        uint96 price;
        bool isActive;
        address creator;
        uint256 createdAt;
        uint256 collectionId; // 0 if not part of collection
        uint256[] aiVariantIds; // AI variants generated for this photo
        mapping(address => EditionOwnership) editionOwners; // Track AI variants per owner // how do we track erc1155 tokens that have multiple users owning them, so multiple ai variants
        address[] ownersList; // List of all owners
        uint32 totalEditionsSold;
    }

    struct PhotoView {
        uint256 tokenId;
        string name;
        string description;
        string tokenURI;
        EditionType editionType;
        uint32 editionSize;
        uint96 price;
        bool isActive;
        address creator;
        uint256 createdAt;
        uint256 collectionId;
        uint256[] aiVariantIds;
        address[] ownersList;
        uint32 totalEditionsSold;
    }

    // track ownership
    struct EditionOwnership {
        uint256 copiesOwned;
        uint256[] aiVariantIds;
        bool exists;
        uint256 purchaseDate;
    }

    struct AiGeneratedVariant {
        uint256 originalPhotoId;
        string aiURI;
        uint256 variantId;
        uint256 generationDate;
        bool isMinted;
        address owner;
        uint256 editionNumber; // Which edition of the original this variant belongs to
    }

    struct UserAiVariant {
        uint256 aiTokenId;
        address owner;
        uint256 originalPhotoTokenId;
    }

    // Function declarations
    function purchase(uint256 _photoId, uint32 _quantity, bool _isUSDC) external payable;

    function getPhotoItem(uint256 tokenId) external view returns (PhotoView memory);

    function createPhoto(
        string calldata name,
        string calldata description,
        string calldata tokenURI,
        uint32 editionSize,
        uint96 price
    ) external returns (uint256);

    // Collection Management Functions
    function createCollection(CollectionCreationParams calldata _createCollectionParams) external returns (uint256);

    function updateCollectionMetadata(
        uint256 _collectionId,
        string calldata _coverImageURI,
        string calldata _featuredPhotoURI,
        string[] calldata _tags
    ) external;

    // AI Variant Functions
    function generateAiVariant(uint256 _tokenId) external returns (bytes32);

    function getAiGenerationStatus(uint256 _tokenId)
        external
        view
        returns (bool inProgress, bool completed, string memory aiUri, uint256 generationDate);

    // Price Management Functions
    function updatePrice(uint256 _tokenId, uint96 _newPrice) external payable;

    function getPrice(uint256 _tokenId) external view returns (uint256);

    // function batchUpdatePrice(
    //   uint256[] calldata tokenIds,
    //   uint96[] calldata prices
    // ) external;

    // View Functions
    function getCollectionPhotos(uint256 _collectionId) external view returns (PhotoView[] memory);

    function getPhoto(uint256 _photoId) external view returns (PhotoView memory);

    function getPhotoOwnership(uint256 _photoId, address _owner) external view returns (EditionOwnership memory);

    function getEditionOwnership(uint256 _tokenId, address _owner) external view returns (EditionOwnership memory);

    function getUserEditionCount(address _user, uint256 _tokenId) external view returns (uint256);

    function verifyMint(uint256 _tokenId) external view returns (bool);

    function getPhotoCounter() external view returns (uint256);

    function getItemsSold() external view returns (uint256);

    function getBuyers() external view returns (address[] memory);

    function getVersion() external pure returns (uint256);

    // Admin Functions
    function withdrawFunds() external;

    // // ERC165 Support
    // function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    // // ERC721/1155 Receiver Functions
    // function onERC721Received(
    //   address operator,
    //   address from,
    //   uint256 tokenId,
    //   bytes calldata data
    // ) external returns (bytes4);

    // function onERC1155Received(
    //   address operator,
    //   address from,
    //   uint256 id,
    //   uint256 value,
    //   bytes calldata data
    // ) external returns (bytes4);

    // function onERC1155BatchReceived(
    //   address operator,
    //   address from,
    //   uint256[] calldata ids,
    //   uint256[] calldata values,
    //   bytes calldata data
    // ) external returns (bytes4);
}
