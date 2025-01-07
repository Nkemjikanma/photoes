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

import {PhotoFactory721} from "./PhotoFactory721.sol";
import {PhotoFactory1155} from "./PhotoFactory1155.sol";
import {IPhotoFactoryEngine} from "./IPhotoFactoryEngine.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

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
    using FunctionsRequest for FunctionsRequest.Request;

    // errors
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

    PhotoFactory721 private factory721;
    PhotoFactory1155 private factory1155;

    address public engine_owner;

    // state variables
    uint256 public constant VERSION = 1;

    uint256 private s_photoCounter; // counter of photos, but used as tokenId
    uint256 private s_aiVariantCounter; // counter of AI variants minted
    uint256 private s_itemsSold; // counter of items sold

    address[] public buyers;

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

    string public ai_generated_svg;

    mapping(uint256 => mapping(address => EditionOwnership)) public editionOwnership;
    // Track who owns how many copies of each edition - tokenid > address > editionOwnership

    mapping(uint256 => PhotoItem) private s_photoItem;
    mapping(uint256 => MultiplePhotoItems) public multiplePhotoItems;
    mapping(uint256 => AiGeneratedVariant) public aiGeneratedVariant;

    // TODO: do i really need this? Single sourceo of truth is up.
    mapping(address => mapping(uint256 => uint256)) public userEditionCount; // user => tokenId => number of editions owned
    mapping(uint256 => mapping(address => uint256[])) public userAiVariants; // tokenId => user => array of their AI variant tokenIds
    mapping(uint256 => uint256[]) private tokenIdToAiVariants; // original tokenId => array of AI variant tokenIds*** - convert to function to call tokenId to aiVariant in PhotoItem struct.

    // AI generation state variables
    mapping(bytes32 => uint256) private requestIdToTokenId; // Track which request belongs to which token
    mapping(uint256 => bool) private aiGenerationInProgress; // Track if AI generation is in progress

    event MintSuccessful(
        address indexed minter, uint256 indexed tokenId, string tokenURI, uint256 price, bool isERC721
    );

    event RoyaltyUpdated(uint256 indexed tokenId, address receiver, uint96 feeNumerator);

    event AIGenerationRequested(uint256 indexed tokenId, bytes32 requestId);
    event AIGenerationCompleted(uint256 indexed tokenId, uint256 indexed aiVariantId, string aiURI);
    event AIGenerationFailed(uint256 indexed tokenId, bytes error);
    event AIVariantMinted(uint256 indexed originalTokenId, uint256 indexed aiTokenId);

    // Event to log responses
    event Response(bytes32 indexed requestId, string character, bytes response, bytes err);

    event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);

    modifier onlyPhotoOwner(uint256 _tokenId) {
        // TODO: || msg.sender != multiplePhotoItems[_tokenId].owner
        if (msg.sender != s_photoItem[_tokenId].owner) {
            revert PhotoFactoryEngine__InvalidOwner();
        }
        _;
    }

    // Check if the photo exists
    modifier existingPhoto(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert PhotoFactoryEngine__InvalidPhotoTokenId();
        _;
    }

    modifier copiesOwnedToAiCheck(address _imageOwner, uint256 _tokenId) {
        EditionOwnership storage ownership = editionOwnership[_tokenId][_imageOwner];

        if (ownership.aiVariantIds.length >= ownership.copiesOwned) {
            revert PhotoFactoryEngine__ExceededAiVariantAllowed();
        }
        _;
    }

    /**
     * @notice Initializes the contract with other smart contracts, Chainlink router address and sets the contract owner
     */
    constructor(
        address photoFactory721Address,
        address photoFactory1155Address,
        uint64 _subscriptionId,
        address _routerAddress,
        bytes32 _donId,
        uint32 _gasLimit,
        address _engineOwner
    ) FunctionsClient(_routerAddress) ConfirmedOwner(_engineOwner) 
    // Ownable(initialOwner)
    {
        factory721 = PhotoFactory721(photoFactory721Address);
        factory1155 = PhotoFactory1155(photoFactory1155Address);
        subscriptionId = _subscriptionId;
        donId = _donId;
        gasLimit = _gasLimit;
        routerAddress = _routerAddress;
        engine_owner = _engineOwner;
        s_photoCounter = 0;
        s_itemsSold = 0;
    }

    //TODO: when mint fails, does variable changed in the function call restore to previoius state
    function mint(
        string memory _tokenURI,
        string memory _description,
        string memory _photoName,
        uint256 _price,
        uint256 _editionSize
    ) external nonReentrant {
        if (_editionSize < 1) {
            revert PhotoFactoryEngine__InvalidEditionSize();
        }

        uint256 tokenId = s_photoCounter + 1;
        s_photoCounter = tokenId;

        if (_exists(tokenId)) {
            revert PhotoFactory721__TokenAlreadyExists();
        }

        if (_editionSize == 1) {
            s_photoItem[tokenId] = PhotoItem({
                tokenId: tokenId,
                photoName: _photoName,
                editionSize: 1,
                tokenURI: _tokenURI,
                description: _description,
                owner: payable(owner()),
                minted: false,
                purchased: false,
                price: _price,
                aiVariantTokenId: 0
            });

            try factory721.mintERC721(_tokenURI, tokenId) {
                s_photoItem[tokenId].minted = true;
                emit MintSuccessful(owner(), tokenId, _tokenURI, _price, true);
            } catch {
                revert PhotoFactoryEngine__MintFailed();
            }
        } else {
            multiplePhotoItems[tokenId] = MultiplePhotoItems({
                tokenId: tokenId,
                photoName: _photoName,
                editionSize: _editionSize,
                tokenURI: _tokenURI,
                description: _description,
                owners: new address[](0),
                price: _price,
                minted: false,
                totalPurchased: 0,
                aiVariantTokenIds: new uint256[](0)
            });

            try factory1155.mint(address(this), tokenId, _editionSize, abi.encodePacked(_tokenURI)) {
                multiplePhotoItems[tokenId].minted = true;

                emit MintSuccessful(msg.sender, tokenId, _tokenURI, _price, false);
            } catch {
                revert PhotoFactoryEngine__MintFailed();
            }
        }
    }

    function decidePhotoEdition(uint256 _tokenId) internal view returns (bool, bool) {
        bool isSingleEdition = s_photoItem[_tokenId].editionSize == 1;
        bool isMultipleEdition = multiplePhotoItems[_tokenId].editionSize > 1;

        return (isSingleEdition, isMultipleEdition);
    }

    function purchase(uint256 _tokenId, uint256 _quantity) public payable existingPhoto(_tokenId) nonReentrant {
        // Initial checks
        if (_quantity == 0) revert PhotoFactoryEngine__InvalidAmount();
        if (msg.value == 0) revert PhotoFactoryEngine__InvalidAmount();

        (bool isSingleEdition, bool isMultipleEdition) = decidePhotoEdition(_tokenId);

        if (isSingleEdition) {
            _purchaseSingleEdition(s_photoItem[_tokenId], msg.value, _tokenId);
        }

        if (isMultipleEdition) {
            _purchaseMultipleEdition(multiplePhotoItems[_tokenId], _quantity, msg.value, _tokenId);
        }

        //msg.value == price * _quantity
        // if users sends more money, then get the required amount and return the balance.

        // Transfer funds to the owner
        _processPayment(msg.value);
        _updateBuyersList(msg.sender);

        // emit PurchaseSuccessful(_tokenId, msg.sender, _quantity, pt)
    }

    function _purchaseSingleEdition(PhotoItem storage _photo, uint256 _payment, uint256 _tokenId) private {
        if (_photo.purchased) revert PhotoFactoryEngine__AlreadyBought();

        if (_photo.owner == msg.sender) {
            revert PhotoFactoryEngine__AlreadyBought();
        }

        if (_payment < _photo.price) {
            revert PhotoFactoryEngine__AmountTooLow();
        }

        factory721.transferERC721(address(this), msg.sender, _tokenId);

        _photo.owner = msg.sender;
        _photo.purchased = true;

        editionOwnership[_tokenId][msg.sender] =
            EditionOwnership({copiesOwned: 1, aiVariantIds: new uint256[](0), canMintAi: true});

        // TODO: do i really need this? Single sourceo of truth is up.
        userEditionCount[msg.sender][_tokenId] = 1; // track how many editions

        // // Generate AI variant
        // generateAiVariant(_tokenId, _photo.tokenURI);

        s_itemsSold++;
    }

    function _purchaseMultipleEdition(
        MultiplePhotoItems storage _photo,
        uint256 _quantity,
        uint256 _payment,
        uint256 _tokenId
    ) private {
        uint256 totalCost = _photo.price * _quantity;
        uint256 remainingEditions = _photo.editionSize - _photo.totalPurchased;

        if (_quantity == 0 || _quantity > remainingEditions) {
            revert PhotoFactoryEngine__ExceededEditionSize(_photo.editionSize, remainingEditions);
        }

        if (_payment != totalCost) {
            revert PhotoFactoryEngine__InvalidAmount();
        }

        factory1155.transferERC1155(address(this), msg.sender, _tokenId, _quantity, "");

        // update ownership
        EditionOwnership storage ownership = editionOwnership[_tokenId][msg.sender];
        ownership.copiesOwned += _quantity;
        ownership.canMintAi = true;
        if (ownership.aiVariantIds.length == 0) {
            ownership.aiVariantIds = new uint256[](0);
        }

        // TODO: // create a modifier/function to check the number of ai variants that users with multiple editions can generate

        userEditionCount[msg.sender][_tokenId] += _quantity; // track how many editions

        _photo.totalPurchased += _quantity;
        _photo.owners.push(msg.sender);

        // // Generate AI variant
        // generateAiVariant(_tokenId, _photo.tokenURI);

        s_itemsSold++;
    }

    /**
     * @notice Sends an HTTP request for ai generated SVG variant
     * @param _tokenId The ID for the photoItem
     * @param _tokenURI the URI of the token
     * @return requestId The ID of the request
     */
    function generateAiVariant(uint256 _tokenId, string memory _tokenURI)
        external
        existingPhoto(_tokenId)
        onlyPhotoOwner(_tokenId)
        copiesOwnedToAiCheck(msg.sender, _tokenId)
        returns (bytes32 requestId)
    {
        // Check if AI generation is already in progress
        if (aiGenerationInProgress[_tokenId]) {
            revert PhotoFactoryEngine__AIGenerationInProgress();
        }

        // Mark AI generation as in progress
        aiGenerationInProgress[_tokenId] = true;

        // send request to chainlink oracle node
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        // Set the token URI as an argument
        string[] memory args = new string[](1);
        args[0] = _tokenURI;

        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donId);

        // Store the request ID to token ID mapping
        requestIdToTokenId[s_lastRequestId] = _tokenId;

        emit AIGenerationRequested(_tokenId, s_lastRequestId);

        return s_lastRequestId;
    }

    function mintAiVariant(uint256 _tokenId, uint256 _aiVariantId, address _sender)
        internal
        // existingPhoto(_tokenId)
        // onlyPhotoOwner(_tokenId)
        nonReentrant
    {
        // ensure AI generation is complete
        AiGeneratedVariant memory aiVariant = aiGeneratedVariant[_aiVariantId]; // get the AI variant

        if (
            aiGenerationInProgress[_tokenId] || aiVariant.minted || aiVariant.generationDate == 0
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
        string memory aiTokenURI = tokenURI(_aiVariantId, aiVariant);

        // Mint the AI variant as an ERC721
        try factory721.mintERC721(aiTokenURI, aiVariant.variantId) {
            // Update mappings and state

            (bool isSingleEdition, bool isMultipleEdition) = decidePhotoEdition(_tokenId);

            if (isSingleEdition) {
                s_photoItem[_tokenId].aiVariantTokenId = aiVariant.variantId;
            }

            if (isMultipleEdition) {
                multiplePhotoItems[_tokenId].aiVariantTokenIds.push(aiVariant.variantId);
            }

            aiVariant.aiURI = aiTokenURI;
            aiVariant.minted = true;
            aiVariant.description = aiVariant.description;
            emit AIVariantMinted(_tokenId, aiVariant.variantId);
        } catch {
            revert PhotoFactoryEngine__MintFailed();
        }

        // update mappings
        tokenIdToAiVariants[_tokenId].push(aiVariant.variantId);
    }

    function tokenURI(uint256 _aiVariantTokenId, AiGeneratedVariant memory aiVariant)
        public
        view
        returns (string memory)
    {
        // AiGeneratedVariant memory aiVariant = aiGeneratedVariant[_aiVariantTokenId];

        string memory imageURI = aiVariant.aiURI;
        string memory name;

        // sample description -  "description": "An NFT that reflects owners mood.", "attribures": [{"trait_type": "moodiness", "value":100}]
        string memory description = aiVariant.description;

        if (s_photoItem[aiVariant.originalImage].minted) {
            name = s_photoItem[aiVariant.originalImage].photoName;
        } else if (multiplePhotoItems[aiVariant.originalImage].minted) {
            name = multiplePhotoItems[aiVariant.originalImage].photoName;
        } else {
            revert PhotoFactoryEngine__InvalidPhotoTokenId();
        }
        if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(""))) {
            revert PhotoFactoryEngine_InvalidAiVariantTokenId();
        }

        string memory tokenMetadata = string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "', name, '", "description": "', description, '", "image": "', imageURI, '"  }'
                        )
                    )
                )
            )
        );

        return tokenMetadata;
    }

    // Verify how to withdraw funds from all contracts
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;

        _processPayment(balance);
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
        uint256 tokenId = requestIdToTokenId[requestId];

        // Update request tracking
        delete requestIdToTokenId[requestId];
        aiGenerationInProgress[tokenId] = false;

        // Handle errors
        if (err.length > 0) {
            emit AIGenerationFailed(tokenId, err);
            return;
        }

        // Update the contract's state variables with the response and any errors
        // response body should hold svg data, metadata such as description etc and the token URI
        s_aiVariantCounter++;
        string memory aiURI = string(response);
        aiGeneratedVariant[s_aiVariantCounter] = AiGeneratedVariant({
            aiURI: aiURI,
            originalImage: tokenId,
            description: "", // TODO: add description returned from ai
            variantId: s_aiVariantCounter,
            generationDate: block.timestamp,
            minted: false
        });

        s_lastResponse = response;
        ai_generated_svg = aiGeneratedVariant[s_aiVariantCounter].aiURI;
        s_lastError = err;

        // Emit an event to log the response
        emit AIGenerationCompleted(tokenId, s_aiVariantCounter, ai_generated_svg);
        emit Response(requestId, ai_generated_svg, s_lastResponse, s_lastError);

        mintAiVariant(tokenId, s_aiVariantCounter, msg.sender);
    }

    // Add a function to check AI generation status
    function getAiGenerationStatus(uint256 _tokenId)
        public
        view
        returns (bool inProgress, bool completed, string memory aiUri, uint256 generationDate)
    {
        inProgress = aiGenerationInProgress[_tokenId];
        AiGeneratedVariant memory variant = aiGeneratedVariant[_tokenId];

        completed = bool(variant.generationDate != 0);
        aiUri = variant.aiURI;
        generationDate = variant.generationDate;
    }

    // Allow contract to receive ETH
    receive() external payable {}

    fallback() external payable {}

    function _baseURI() internal pure returns (string memory) {
        return "data:application/json;base64";
    }

    function _processPayment(uint256 amount) private {
        (bool success,) = payable(owner()).call{value: amount}("");
        if (!success) revert PhotoFactoryEngine__TransactionFailed();
    }

    function _updateBuyersList(address buyer) private {
        if (!_isNewBuyer(buyer)) {
            buyers.push(buyer);
        }
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        bool exists = false;

        if (s_photoItem[tokenId].minted == true || multiplePhotoItems[tokenId].minted == true) {
            exists = true;
        }

        return exists;
    }

    function updatePrice(uint256 _tokenId, uint256 _newPrice) public payable onlyOwner existingPhoto(_tokenId) {
        // implement price update for multiple photos as well, - when no buyer**
        s_photoItem[_tokenId].price = _newPrice;
        emit PriceUpdated(_tokenId, _newPrice);
    }

    function getPrice(uint256 _tokenId) public view returns (uint256) {
        (bool isSingleEdition, bool isMultipleEdition) = decidePhotoEdition(_tokenId);

        if (isSingleEdition) {
            return s_photoItem[_tokenId].price;
        }

        if (isMultipleEdition) {
            return multiplePhotoItems[_tokenId].price;
        }
    }

    function verifyMint(uint256 tokenId) public view returns (bool) {
        bool minted = false;
        if (s_photoItem[tokenId].minted == true || multiplePhotoItems[tokenId].minted) {
            minted = true;
        }

        return minted;
    }

    function _isNewBuyer(address _address) private view returns (bool) {
        for (uint256 i = 0; i < buyers.length; i++) {
            if (buyers[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getPhotoCounter() public view returns (uint256) {
        return s_photoCounter;
    }

    // improve
    function getItemsSold() public view returns (uint256) {
        return s_itemsSold;
    }

    function getBuyers() public view returns (address[] memory) {
        return buyers;
    }

    function getVersion() public pure returns (uint256) {
        return VERSION;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // TODO: Implement batch purchase - draft state
    function batchPurchase(uint256[] calldata tokenIds, uint256[] calldata quantities) external payable {
        require(tokenIds.length == quantities.length, "Length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            purchase(tokenIds[i], quantities[i]);
        }
    }

    function batchUpdatePrice(uint256[] calldata tokenIds, uint256[] calldata prices) external onlyOwner {
        require(tokenIds.length == prices.length, "Length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            updatePrice(tokenIds[i], prices[i]);
        }
    }

    function getMultiplePhotoItems(uint256 _tokenId) public view returns (MultiplePhotoItems memory) {
        MultiplePhotoItems memory photo = multiplePhotoItems[_tokenId];

        return photo;
    }

    function getPhotoItem(uint256 tokenId) public view returns (PhotoItem memory) {
        return s_photoItem[tokenId];
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
