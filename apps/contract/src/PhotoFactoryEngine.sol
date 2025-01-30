// SPDX-License-Identifier: MIT

// TODO: Add to collection helper function
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

import {PhotoFactory721} from "./PhotoFactory721.sol";
import {PhotoFactory1155} from "./PhotoFactory1155.sol";
import {IPhotoFactoryEngine} from "./interfaces/IPhotoFactoryEngine.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import {PriceConverter} from "./libs/PriceConverter.sol";
import {PurchaseHandler} from "./libs/PurchaseHandler.sol";

/*
 * @title PhotoFactoryEngine
 * @author Nkemjika
 * @notice This contract is the handler for PhotoFactory721 and PhotoFactory1155 - automatically deciding what contract to call for mints. It also uses chainlink functions to call an external API to generate AI variants of the photos.
 * The owner mints and sets the prices of the photographs and users can purchase them.
 * @notice further implementation should include reselling of photos
 * @dev Implements ERC1155, ERC1155SUPPLY, ConfirmedOwner, FunctionsClient, ReentrancyGuard
 */
contract PhotoFactoryEngine is
    ReentrancyGuard,
    FunctionsClient,
    ConfirmedOwner,
    IERC721Receiver,
    IERC1155Receiver,
    IPhotoFactoryEngine
{
    /*//////////////////////////////////////////////////////////////
                             LIBRARIES
    //////////////////////////////////////////////////////////////*/

    // Attach priceconverter function lib to all uint256
    using PriceConverter for uint256;
    using FunctionsRequest for FunctionsRequest.Request;
    using PurchaseHandler for *;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error PhotoFactoryEngine__EditionSizeMustBeGreaterThanZero();
    error PhotoFactoryEngine__PhotoAlreadyMinted();
    error PhotoFactoryEngine__InvalidTokenURI();
    error PhotoFactoryEngine_InvalidAiVariantTokenId();
    error PhotoFactoryEngine__TokenAIError();
    error PhotoFactoryEngine__EditionCopiesExhausted();
    error PhotoFactoryEngine__InvalidAmount(); // invalid mint amount
    error PhotoFactoryEngine__AmountTooLow();
    error PhotoFactoryEngine__MintFailed(); // minting failed error
    error PhotoFactoryEngine__InvalidEditionSize();
    error PhotoFactoryEngine__TransactionFailed();
    error PhotoFactoryEngine__InvalidPhotoTokenId();
    error PhotoFactoryEngine__InvalidPrice();
    error PhotoFactoryEngine__InvalidOwner();
    error PhotoFactoryEngine__AlreadyBought();
    error PhotoFactoryEngine__AIGenerationInProgress();
    error PhotoFactoryEngine__AIGenerationNotStarted();
    error PhotoFactoryEngine__TokenAI();
    error UnexpectedRequestID(bytes32 requestId);
    error PhotoFactory721__TokenAlreadyExists();
    error PhotoFactoryEngine__ExceededEditionSize(uint256 editionSize, uint256 remainingEditions);
    error PhotoFactoryEngine__ExceededAiVariantAllowed();
    error PhotoFactoryEngine__WithdrawFailed();
    error PhotoFactoryEngine__NoFundsToWithdraw();
    error PhotoFactoryEngine__InvalidMintParameters();

    error PhotoFactoryEngine__InvalidCollectionParams();
    error PhotoFactoryEngine__CollectionNotFound();
    error PhotoFactoryEngine__MaxPhotosExceeded();
    error PhotoFactoryEngine__InvalidPhotoCount();

    /*//////////////////////////////////////////////////////////////
                               STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // CONSTANTS
    uint256 public constant VERSION = 1;

    PhotoFactory721 private factory721;
    PhotoFactory1155 private factory1155;

    // price feed for l2
    AggregatorV2V3Interface internal s_priceFeed;

    address public usdcAddress;

    address public engine_owner;

    uint256 private s_photoCounter; // counter of photos, but used as tokenId
    uint256 private s_collectionCounter; // counter of collections
    uint256 private s_aiVariantCounter; // counter of AI variants minted
    uint256 private s_itemsSold; // counter of items sold
    address[] public buyers;

    mapping(uint256 => Photo) private s_photos; // track photos
    mapping(uint256 => Collection) private s_collections;

    // Chainlink function variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    address routerAddress;
    uint64 subscriptionId;

    // JavaScript source code
    // Fetch svg from BE api - should return name, and description.
    string source = "const characterId = args[0];" "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://swapi.info/api/people/${characterId}/`" "});" "if (apiResponse.error) {"
        "throw Error('Request failed');" "}" "const { data } = apiResponse;" "return Functions.encodeString(data.name);";

    // string source =
    //     "const tokenUri = args[0];"
    //     "const apiResponse = await Functions.makeHttpRequest({"
    //     "  url: 'https://your-ai-service.com/generate',"
    //     "  method: 'POST',"
    //     "  headers: {"
    //     "    'Content-Type': 'application/json'"
    //     "  },"
    //     "  data: {"
    //     "    'original_uri': tokenUri,"
    //     "    'style': 'artistic',"
    //     "    'enhance': true"
    //     "  }"
    //     "});"
    //     "if (apiResponse.error) {"
    //     "  throw Error('AI generation failed');"
    //     "}"
    //     "return Functions.encodeString(apiResponse.data.ai_variant_uri);";

    //Callback gas limit
    uint32 gasLimit;

    bytes32 donId;

    struct PendingAiRequest {
        uint256 photoId;
        address owner;
        uint256 editionNumber;
    }

    mapping(bytes32 => PendingAiRequest) private s_pendingRequests;

    string public ai_generated_svg;

    mapping(uint256 => AiGeneratedVariant) public s_aiVariants;

    // Counter for tracking AI variants

    // AI generation state variables
    mapping(bytes32 => uint256) private requestIdToTokenId; // Track which request belongs to which token
    mapping(uint256 => bool) private aiGenerationInProgress; // Track if AI generation is in progress

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RoyaltyUpdated(uint256 indexed tokenId, address receiver, uint96 feeNumerator);

    // Event to log responses
    event Response(bytes32 indexed requestId, string character, bytes response, bytes err);

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyPhotoOwner(uint256 _tokenId) {
        // TODO: || msg.sender != multiplePhotoItems[_tokenId].owner

        for (uint256 i = 0; i <= s_photos[_tokenId].ownersList.length; i++) {
            if (msg.sender != s_photos[_tokenId].ownersList[i]) {
                revert PhotoFactoryEngine__InvalidOwner();
            }
        }
        _;
    }

    // Check if the photo exists
    modifier existingPhoto(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert PhotoFactoryEngine__InvalidPhotoTokenId();
        _;
    }

    modifier copiesOwnedToAiCheck(address _imageOwner, uint256 _tokenId) {
        IPhotoFactoryEngine.EditionOwnership storage ownership = s_photos[_tokenId].editionOwners[_imageOwner];

        if (ownership.aiVariantIds.length >= ownership.copiesOwned) {
            revert PhotoFactoryEngine__ExceededAiVariantAllowed();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with other smart contracts, Chainlink router address and sets the contract owner
     */
    constructor(
        address _photoFactory721,
        address _photoFactory1155,
        uint64 _subscriptionId,
        address _routerAddress,
        bytes32 _donId,
        uint32 _gasLimit,
        address _engineOwner,
        address _priceFeed,
        address _usdcAddress
    ) FunctionsClient(_routerAddress) ConfirmedOwner(_engineOwner)
    // Ownable(initialOwner)
    {
        factory721 = PhotoFactory721(_photoFactory721);
        factory1155 = PhotoFactory1155(_photoFactory1155);
        subscriptionId = _subscriptionId;
        donId = _donId;
        gasLimit = _gasLimit;
        routerAddress = _routerAddress;
        engine_owner = _engineOwner;
        s_photoCounter = 0;
        s_collectionCounter = 0;
        s_itemsSold = 0;
        s_priceFeed = AggregatorV2V3Interface(_priceFeed);
        usdcAddress = _usdcAddress;
    }

    /**
     * @notice Create a single photo item to be minted
     */
    function createPhoto(
        string calldata _name,
        string calldata _description,
        string calldata _tokenURI,
        uint32 _editionSize,
        uint96 _price
    ) external override onlyOwner returns (uint256) {
        if (_editionSize == 0) {
            revert PhotoFactoryEngine__EditionSizeMustBeGreaterThanZero();
        }

        EditionType editionType = _editionSize == 1 ? EditionType.Single : EditionType.Multiple;

        MintPhotoParams memory params = MintPhotoParams({
            name: _name,
            description: _description,
            tokenURI: _tokenURI,
            editionType: editionType,
            editionSize: _editionSize,
            price: _price,
            collectionId: 0 // not part of a collection
        });

        return _mintPhoto(params);
    }

    /**
     * @notice CreateCollection creates a collection of photos
     * @param  _createCollectionParams The parameters for creating a collection
     * @return collectionId The ID of the created collection
     */
    function createCollection(CollectionCreationParams calldata _createCollectionParams)
        external
        override
        onlyOwner
        returns (uint256)
    {
        if (
            bytes(_createCollectionParams.name).length == 0 || bytes(_createCollectionParams.description).length == 0
                || _createCollectionParams.photoCreationParams.length == 0
        ) {
            revert PhotoFactoryEngine__InvalidCollectionParams();
        }

        uint256 collectionId = ++s_collectionCounter;
        _initializeCollection(
            collectionId,
            _createCollectionParams.name,
            _createCollectionParams.description,
            _createCollectionParams.categories,
            _createCollectionParams.coverImageURI,
            _createCollectionParams.featuredPhotoURI,
            _createCollectionParams.tags
        );

        // Split photo creation into separate function
        _createCollectionPhotos(collectionId, _createCollectionParams.photoCreationParams);

        emit CollectionCreated(
            collectionId, _createCollectionParams.name, msg.sender, _createCollectionParams.photoCreationParams.length
        );
        return collectionId;
    }

    function _initializeCollection(
        uint256 _collectionId,
        string calldata _name,
        string calldata _description,
        CollectionCategory[] calldata _categories,
        string calldata _coverImageURI,
        string calldata _featuredPhotoURI,
        string[] calldata _tags
    ) private {
        Collection storage newCollection = s_collections[_collectionId];

        newCollection.collectionId = _collectionId;
        newCollection.name = _name;
        newCollection.description = _description;
        newCollection.creator = msg.sender;
        newCollection.createdAt = block.timestamp;

        for (uint256 i = 0; i < _categories.length; i++) {
            newCollection.category.push(_categories[i]);
        }

        newCollection.metadata.coverImageURI = _coverImageURI;
        newCollection.metadata.featuredPhotoURI = _featuredPhotoURI;
        newCollection.metadata.tags = _tags;
    }

    function _createCollectionPhotos(uint256 _collectionId, PhotoCreationParams[] calldata _photoCreationParams)
        private
    {
        Collection storage collection = s_collections[_collectionId];

        for (uint256 i = 0; i < _photoCreationParams.length; i++) {
            PhotoCreationParams memory params = _photoCreationParams[i];
            EditionType editionType = params.editionSize == 1 ? EditionType.Single : EditionType.Multiple;

            MintPhotoParams memory mintParams = MintPhotoParams({
                name: params.name,
                description: params.description,
                tokenURI: params.tokenURI,
                editionType: editionType,
                editionSize: params.editionSize,
                price: params.price,
                collectionId: _collectionId // not part of a collection
            });

            uint256 photoId = _mintPhoto(mintParams);

            collection.photoIds.push(photoId);
            emit PhotoAddedToCollection(_collectionId, photoId);
        }
    }

    //TODO: when mint fails, does variable changed in the function call restore to previoius state
    /**
     * @notice MintPhoto the NFT so users can purchase.
     * @param params The parameters of minting the photo
     * @dev Reverts if edition size is 0, if price is 0, no tokenURI or photoName and if minting fails
     */
    function _mintPhoto(MintPhotoParams memory params) internal nonReentrant onlyOwner returns (uint256) {
        if (bytes(params.tokenURI).length == 0 || bytes(params.name).length == 0) {
            revert PhotoFactoryEngine__InvalidMintParameters();
        }
        if (params.editionSize < 1) {
            revert PhotoFactoryEngine__InvalidEditionSize();
        }

        uint256 tokenId;

        unchecked {
            tokenId = s_photoCounter + 1;
            s_photoCounter = tokenId;
        }

        if (_exists(tokenId)) {
            revert PhotoFactory721__TokenAlreadyExists();
        }

        Photo storage photo = s_photos[tokenId];
        photo.tokenId = tokenId;
        photo.name = params.name;
        photo.description = params.description;
        photo.tokenURI = params.tokenURI;
        photo.editionType = params.editionType;
        photo.editionSize = params.editionSize;
        photo.price = params.price;
        photo.creator = msg.sender;
        photo.createdAt = block.timestamp;
        photo.isActive = true;
        photo.collectionId = params.collectionId;

        // Mint the token based on edition type
        if (params.editionType == EditionType.Single) {
            factory721.mintERC721(params.tokenURI, tokenId);
        } else {
            factory1155.mint(address(this), tokenId, params.editionSize, abi.encodePacked(params.tokenURI));
        }

        emit PhotoCreated(tokenId, params.editionType, params.editionSize, params.collectionId);
        return tokenId;
    }

    /**
     * @notice Update collection metadata
     */
    function updateCollectionMetadata(
        uint256 _collectionId,
        string calldata _coverImageURI,
        string calldata _featuredPhotoURI,
        string[] calldata _tags
    ) external override onlyOwner {
        Collection storage collection = s_collections[_collectionId];
        require(collection.createdAt != 0, "Collection not found");

        collection.metadata.coverImageURI = _coverImageURI;
        collection.metadata.featuredPhotoURI = _featuredPhotoURI;
        collection.metadata.tags = _tags;

        emit CollectionMetadataUpdated(_collectionId, _coverImageURI, _featuredPhotoURI);
    }

    /**
     * @notice Purchase The function to buy minted Photograph.
     * @param _photoId The id for the token to be bought.
     * @param _quantity The quantity of images to buy, Always 1 for ERC721.
     * @param _isUSDC boolead to determin if payment is in USDC or ETH.
     */
    function purchase(uint256 _photoId, uint32 _quantity, bool _isUSDC)
        external
        payable
        override
        existingPhoto(_photoId)
        nonReentrant
    {
        Photo storage photo = s_photos[_photoId];
        uint32 totalEditionsSold = photo.totalEditionsSold; // Cache storage read

        // Initial checks
        if (msg.value == 0) {
            revert PhotoFactoryEngine__InvalidAmount();
        }

        // handle edition size check for single and multiple edition types
        if ((totalEditionsSold + _quantity) > photo.editionSize) {
            revert PhotoFactoryEngine__EditionCopiesExhausted();
        }

        // Get price directly from photo
        uint96 price = photo.price;
        uint96 totalCost = price * _quantity;

        // Handle payment
        // _handlePayment(_isUSDC, totalCost);
        if (_isUSDC) {
            PurchaseHandler.handleUSDCPayment(usdcAddress, msg.sender, totalCost);
        } else {
            // Transfer funds to the owner
            if (msg.value < totalCost) revert PhotoFactoryEngine__InvalidAmount();
            PurchaseHandler.handleETHPayment(msg.value, totalCost, payable(owner()));
        }

        // Update ownership
        _updatePhotoOwnership(_photoId, msg.sender, _quantity);

        // Handle token transfer
        if (photo.editionType == EditionType.Single) {
            require(_quantity == 1, "Single edition quantity must be 1");
            factory721.safeTransferFrom(address(this), msg.sender, _photoId);
            totalEditionsSold = 1;
        } else {
            factory1155.safeTransferFrom(address(this), msg.sender, _photoId, _quantity, "");

            totalEditionsSold += _quantity;
        }

        emit PhotoPurchased(_photoId, msg.sender, _quantity, totalCost);
    }

    function _updatePhotoOwnership(uint256 _photoId, address _buyer, uint32 _quantity) private {
        Photo storage photo = s_photos[_photoId];

        if (!photo.editionOwners[_buyer].exists) {
            photo.ownersList.push(_buyer);
            photo.editionOwners[_buyer].exists = true;
            photo.editionOwners[_buyer].purchaseDate = block.timestamp;
        }

        photo.editionOwners[_buyer].copiesOwned += _quantity;
        photo.totalEditionsSold += _quantity;
    }

    /**
     * @notice GenerateAiVariant sends an HTTP request for ai generated SVG variant
     * @param _tokenId The ID for the photoItem
     * @return requestId The ID of the request
     */
    function generateAiVariant(uint256 _tokenId)
        external
        override
        existingPhoto(_tokenId)
        onlyPhotoOwner(_tokenId)
        copiesOwnedToAiCheck(msg.sender, _tokenId)
        returns (bytes32 requestId)
    {
        // Check if AI generation is already in progress
        if (aiGenerationInProgress[_tokenId]) {
            revert PhotoFactoryEngine__AIGenerationInProgress();
        }

        Photo storage photo = s_photos[_tokenId];
        EditionOwnership storage editionInfo = photo.editionOwners[msg.sender];

        // Check if the user has reached the limit of AI variants allowed for this edition
        if (editionInfo.copiesOwned >= editionInfo.aiVariantIds.length) {
            revert PhotoFactoryEngine__ExceededAiVariantAllowed();
        }

        // Mark AI generation as in progress
        aiGenerationInProgress[_tokenId] = true;

        // send request to chainlink oracle node
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code

        // Set the token URI as an argument
        string[] memory args = new string[](1);
        args[0] = photo.tokenURI; // Pass original URI to AI service

        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donId);

        // 7. Store request details for fulfillment
        s_pendingRequests[s_lastRequestId] =
            PendingAiRequest({photoId: _tokenId, owner: msg.sender, editionNumber: editionInfo.aiVariantIds.length + 1});

        // Store the request ID to token ID mapping
        requestIdToTokenId[s_lastRequestId] = _tokenId;

        emit AIGenerationRequested(_tokenId, s_lastRequestId);

        return s_lastRequestId;
    }

    /**
     * @notice Mint the AI variant as an ERC721 token
     * @param _tokenId The ID for the photoItem
     * @param _aiVariantId the URI of the token
     */
    function mintAiVariant(uint256 _tokenId, uint256 _aiVariantId)
        internal
        // existingPhoto(_tokenId)
        // onlyPhotoOwner(_tokenId)
        nonReentrant
    {
        // ensure AI generation is complete
        AiGeneratedVariant memory aiVariant = s_aiVariants[_aiVariantId]; // get the AI variant

        if (
            aiGenerationInProgress[_tokenId] || aiVariant.isMinted || aiVariant.generationDate == 0
                || keccak256(abi.encodePacked(aiVariant.aiURI)) == keccak256(abi.encodePacked(""))
        ) {
            revert PhotoFactoryEngine__TokenAIError();
        }

        /*
     * TODO:
     * Receive svg in base 64,
     * confirm it is in base 64 format
     */

        // Generate the token URI for the AI variant
        string memory aiTokenURI = tokenURI(aiVariant);

        // Mint the AI variant as an ERC721
        try factory721.mintERC721(aiTokenURI, aiVariant.variantId) {
            // Update mappings and state
            aiVariant.aiURI = aiTokenURI;
            aiVariant.isMinted = true;

            // Update the original photo's AI variant tracking
            Photo storage photo = s_photos[_tokenId];

            photo.aiVariantIds.push(aiVariant.variantId);

            emit AIVariantMinted(_tokenId, aiVariant.variantId);
        } catch {
            revert PhotoFactoryEngine__MintFailed();
        }

        // update mappings
        s_photos[_tokenId].aiVariantIds.push(aiVariant.variantId);
    }

    /**
     * @notice TokenURI Generate the token URI for the AI variant
     * @param _aiVariant the URI of the token
     * @return The URI for the AI variant
     */
    function tokenURI(AiGeneratedVariant memory _aiVariant) public view returns (string memory) {
        string memory imageURI = _aiVariant.aiURI;

        // Get the original photo
        Photo storage originalPhoto = s_photos[_aiVariant.originalPhotoId];
        if (originalPhoto.createdAt == 0) {
            revert PhotoFactoryEngine__InvalidPhotoTokenId();
        }

        string memory name = originalPhoto.name;

        // sample description -  "description": "An NFT that reflects owners mood.", "attribures": [{"trait_type": "moodiness", "value":100}]

        if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(""))) {
            revert PhotoFactoryEngine_InvalidAiVariantTokenId();
        }

        string memory tokenMetadata = string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name": "', name, '", "description": "', '", "image": "', imageURI, '"  }')
                    )
                )
            )
        );

        return tokenMetadata;
    }

    /**
     * @notice WithdrawFunds allows the owner to withdraw funds from the contract
     */
    // Verify how to withdraw funds from all contracts
    function withdrawFunds() public override nonReentrant onlyOwner {
        uint256 ethBalance = address(this).balance;
        uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));

        if (ethBalance == 0 && usdcBalance == 0) {
            revert PhotoFactoryEngine__NoFundsToWithdraw();
        }

        if (ethBalance > 0) {
            (bool success,) = payable(owner()).call{value: ethBalance}("");

            if (!success) {
                revert PhotoFactoryEngine__WithdrawFailed();
            }
        }

        if (usdcBalance > 0) {
            bool success = IERC20(usdcAddress).transfer(owner(), usdcBalance);

            if (!success) {
                revert PhotoFactoryEngine__WithdrawFailed();
            }
        }

        emit FundsWithdrawn(owner(), ethBalance, usdcBalance);
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }

        // Get the token ID associated with this request
        PendingAiRequest memory request = s_pendingRequests[requestId];
        uint256 photoId = requestIdToTokenId[requestId];

        // Update request tracking
        delete requestIdToTokenId[requestId];
        delete s_pendingRequests[requestId];
        aiGenerationInProgress[photoId] = false;

        // Handle errors
        if (err.length > 0) {
            emit AIGenerationFailed(photoId, err);
            return;
        }

        // Update the contract's state variables with the response and any errors
        // response body should hold svg data, metadata such as description etc and the token URI
        s_aiVariantCounter++;
        string memory aiURI = string(response);

        s_aiVariants[s_aiVariantCounter] = AiGeneratedVariant({
            originalPhotoId: photoId,
            aiURI: aiURI,
            variantId: s_aiVariantCounter,
            generationDate: block.timestamp,
            isMinted: false,
            owner: request.owner,
            editionNumber: request.editionNumber
        });

        // 7. Update ownership records
        Photo storage photo = s_photos[photoId];
        photo.editionOwners[request.owner].aiVariantIds.push(s_aiVariantCounter);

        s_lastResponse = response;
        s_lastError = err;

        // Emit an event to log the response
        emit AIGenerationCompleted(photoId, s_aiVariantCounter, ai_generated_svg);
        emit Response(requestId, ai_generated_svg, s_lastResponse, s_lastError);

        mintAiVariant(photoId, s_aiVariantCounter);
    }

    /**
     * @notice GetAiGenerationStatus returns the status of AI generation for a given token ID
     * @param _tokenId The ID of the token to check
     */
    function getAiGenerationStatus(uint256 _tokenId)
        public
        view
        override
        returns (bool inProgress, bool completed, string memory aiUri, uint256 generationDate)
    {
        inProgress = aiGenerationInProgress[_tokenId];
        AiGeneratedVariant memory variant = s_aiVariants[_tokenId];

        completed = bool(variant.generationDate != 0);
        aiUri = variant.aiURI;
        generationDate = variant.generationDate;
    }

    /**
     * @notice UpdatePrice updates the price of a photo
     * @param _tokenId the ID of the photo
     * @param _newPrice the new price of the photo
     */
    function updatePrice(uint256 _tokenId, uint96 _newPrice)
        public
        payable
        override
        onlyOwner
        existingPhoto(_tokenId)
    {
        Photo storage photo = s_photos[_tokenId];
        photo.price = _newPrice;

        emit PriceUpdated(_tokenId, _newPrice);
    }

    /**
     * @notice GetPrice returns the price of a photo
     * @param _tokenId the ID of the photo
     * @return uint256 the price of the photo
     */
    function getPrice(uint256 _tokenId) public view override returns (uint256) {
        Photo storage photo = s_photos[_tokenId];
        if (photo.price == 0) {
            revert PhotoFactoryEngine__InvalidPrice();
        }
        return photo.price;
    }

    // Allow contract to receive ETH
    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice ProcessETHPayment concantenates the base URI for the tokenURI
     * @param _amount The amount to be processed
     */
    function _processETHPayment(uint256 _amount) private {
        (bool success,) = payable(owner()).call{value: _amount}("");
        if (!success) revert PhotoFactoryEngine__TransactionFailed();
    }

    /**
     * @notice UpdateBuyersList manages the list of buyers
     */
    function _updateBuyersList(address buyer) private {
        if (!_isNewBuyer(buyer)) {
            buyers.push(buyer);
        }
    }

    /**
     * @notice Get all photos in a collection
     * @param _collectionId The ID of the collection
     * @return collection The collection Object
     */
    function getCollection(uint256 _collectionId) external view override returns (Collection memory) {
        Collection storage collection = s_collections[_collectionId];

        return Collection({
            collectionId: collection.collectionId,
            name: collection.name,
            description: collection.description,
            creator: collection.creator,
            createdAt: collection.createdAt,
            category: collection.category,
            metadata: CollectionMetadata({
                coverImageURI: collection.metadata.coverImageURI,
                featuredPhotoURI: collection.metadata.featuredPhotoURI,
                tags: collection.metadata.tags
            }),
            photoIds: collection.photoIds
        });
    }

    /**
     * @notice Get all photos in a collection
     * @param _collectionId The ID of the collection
     * @return Array of photo IDs in the collection
     */
    function getCollectionPhotos(uint256 _collectionId) external view override returns (PhotoView[] memory) {
        Collection storage collection = s_collections[_collectionId];
        uint256 length = collection.photoIds.length;
        PhotoView[] memory photos = new PhotoView[](length);

        if (collection.createdAt == 0) {
            revert PhotoFactoryEngine__CollectionNotFound();
        }

        for (uint256 i = 0; i < length; i++) {
            uint256 photoId = collection.photoIds[i];
            Photo storage photo = s_photos[photoId];

            photos[i] = PhotoView({
                tokenId: photo.tokenId,
                name: photo.name,
                description: photo.description,
                tokenURI: photo.tokenURI,
                editionType: photo.editionType,
                editionSize: photo.editionSize,
                price: photo.price,
                isActive: photo.isActive,
                creator: photo.creator,
                createdAt: photo.createdAt,
                collectionId: photo.collectionId,
                aiVariantIds: photo.aiVariantIds,
                ownersList: photo.ownersList,
                totalEditionsSold: photo.totalEditionsSold
            });
        }

        return photos;
    }

    /**
     * @notice Check if a photo belongs to a collection
     * @param _photoId The ID of the photo
     * @return collectionId The ID of the collection the photo belongs to (0 if none)
     */
    // function getPhotoCollection(uint256 _photoId) external view returns (uint256) {
    //     return s_photoToCollection[_photoId];
    // }

    /**
     * @notice BaseURI concantenates the base URI for the tokenURI
     * @return string The base uri for the tokenURI
     */
    function _baseURI() public pure returns (string memory) {
        return "data:application/json;base64";
    }

    /**
     * @notice Exists checks if a token exists
     * @param _tokenId The ID of the token to check
     * @return bool True if the token exists, false otherwise
     */
    function _exists(uint256 _tokenId) private view returns (bool) {
        return s_photos[_tokenId].createdAt != 0;
    }

    /**
     * @notice IsNewBuyer checks if the buyer is new
     * @param _address the address of the buyer
     * @return bool True if the buyer is new, false otherwise
     */
    function _isNewBuyer(address _address) private view returns (bool) {
        for (uint256 i = 0; i < buyers.length; i++) {
            if (buyers[i] == _address) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice VerifyMint checks if a token has been minted
     * @param _tokenId The ID of the token to check
     * @return bool True if the token has been minted, false otherwise
     */
    function verifyMint(uint256 _tokenId) external view override returns (bool) {
        return s_photos[_tokenId].createdAt != 0;
    }

    //TODO: Consider multiple deployments if other users can create projects.
    // function getDeployedFactories() external view returns (address[] memory) {
    //     return deployedPhotoFactoryContracts;
    // }

    // function isFactoryDeployed(address _factory) public view returns (bool) {
    //     for (uint256 i = 0; i < deployedPhotoFactoryContracts.length; i++) {
    //         if (deployedPhotoFactoryContracts[i] == _factory) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    /**
     * @notice GetPhotoCounter Get the current number of photos minted
     * @return uint256 The number of photos minted
     */
    function getPhotoCounter() public view override returns (uint256) {
        return s_photoCounter;
    }

    /**
     * @notice GetItemsSold Get the number of Items sold
     * @return uint256 The number of items sold
     */
    // improve
    function getItemsSold() public view override returns (uint256) {
        return s_itemsSold;
    }

    function getBuyers() public view override returns (address[] memory) {
        return buyers;
    }

    function getEditionOwnership(uint256 _tokenId, address _owner)
        public
        view
        override
        returns (IPhotoFactoryEngine.EditionOwnership memory)
    {
        return s_photos[_tokenId].editionOwners[_owner];
    }

    function getUserEditionCount(address _user, uint256 _tokenId) public view override returns (uint256) {
        return s_photos[_tokenId].editionOwners[_user].copiesOwned;
    }

    function getVersion() public pure override returns (uint256) {
        return VERSION;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // TODO: Implement batch purchase - draft state
    // function batchPurchase(uint256[] calldata tokenIds, uint256[] calldata quantities) external payable {
    //     require(tokenIds.length == quantities.length, "Length mismatch");
    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         purchase(tokenIds[i], quantities[i]);
    //     }
    // }

    function batchUpdatePrice(uint256[] calldata tokenIds, uint96[] calldata prices) external onlyOwner {
        require(tokenIds.length == prices.length, "Length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            updatePrice(tokenIds[i], prices[i]);
        }
    }

    /**
     * @notice Get photo details
     */
    function getPhoto(uint256 _photoId) external view override returns (PhotoView memory) {
        Photo storage photo = s_photos[_photoId];

        return PhotoView({
            tokenId: photo.tokenId,
            name: photo.name,
            description: photo.description,
            tokenURI: photo.tokenURI,
            editionType: photo.editionType,
            editionSize: photo.editionSize,
            price: photo.price,
            isActive: photo.isActive,
            creator: photo.creator,
            createdAt: photo.createdAt,
            collectionId: photo.collectionId,
            aiVariantIds: photo.aiVariantIds,
            ownersList: photo.ownersList,
            totalEditionsSold: photo.totalEditionsSold
        });
    }

    /**
     * @notice Get photo ownership details
     */
    function getPhotoOwnership(uint256 _photoId, address _owner)
        external
        view
        override
        returns (EditionOwnership memory)
    {
        return s_photos[_photoId].editionOwners[_owner];
    }

    function getPhotoItem(uint256 _tokenId) external view override returns (PhotoView memory) {
        Photo storage photo = s_photos[_tokenId];
        return PhotoView({
            tokenId: photo.tokenId,
            name: photo.name,
            description: photo.description,
            tokenURI: photo.tokenURI,
            editionType: photo.editionType,
            editionSize: photo.editionSize,
            price: photo.price,
            isActive: photo.isActive,
            creator: photo.creator,
            createdAt: photo.createdAt,
            collectionId: photo.collectionId,
            aiVariantIds: photo.aiVariantIds,
            ownersList: photo.ownersList,
            totalEditionsSold: photo.totalEditionsSold
        });
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
