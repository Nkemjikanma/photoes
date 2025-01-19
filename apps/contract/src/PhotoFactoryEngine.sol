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
  // attaching the price converter lib
  using PriceConverter for uint256;
  using PurchaseHandler for *;

  // price feed for l2
  AggregatorV2V3Interface internal s_priceFeed;

  using FunctionsRequest for FunctionsRequest.Request;

  // Attach priceconverter function lib to all uint256
  using PriceConverter for uint256;

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
  error PhotoFactoryEngine__ExceededEditionSize(
    uint256 editionSize,
    uint256 remainingEditions
  );
  error PhotoFactoryEngine__ExceededAiVariantAllowed();
  error PhotoFactoryEngine__WithdrawFailed();
  error PhotoFactoryEngine__NoFundsToWithdraw();

  PhotoFactory721 private factory721;
  PhotoFactory1155 private factory1155;

  PurchaseHandler.PurchaseState private s_purchaseState;

  address public usdcAddress;

  address public engine_owner;

  // state variables
  uint256 public constant VERSION = 1;

  uint256 private s_photoCounter; // counter of photos, but used as tokenId
  uint256 private s_aiVariantCounter; // counter of AI variants minted
  uint256 private s_itemsSold; // counter of items sold

  // Chainlink function variables to store the last request ID, response, and error
  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;

  address routerAddress;
  uint64 subscriptionId;

  // JavaScript source code
  // Fetch svg from BE api - should return name, and description.
  string source =
    "const characterId = args[0];"
    "const apiResponse = await Functions.makeHttpRequest({"
    "url: `https://swapi.info/api/people/${characterId}/`"
    "});"
    "if (apiResponse.error) {"
    "throw Error('Request failed');"
    "}"
    "const { data } = apiResponse;"
    "return Functions.encodeString(data.name);";

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

  mapping(uint256 => AiGeneratedVariant) public aiGeneratedVariant;

  // TODO: do i really need this? Single sourceo of truth is up.
  mapping(uint256 => mapping(address => uint256[])) public userAiVariants; // tokenId => user => array of their AI variant tokenIds
  mapping(uint256 => uint256[]) private tokenIdToAiVariants; // original tokenId => array of AI variant tokenIds*** - convert to function to call tokenId to aiVariant in PhotoItem struct.

  // AI generation state variables
  mapping(bytes32 => uint256) private requestIdToTokenId; // Track which request belongs to which token
  mapping(uint256 => bool) private aiGenerationInProgress; // Track if AI generation is in progress

  event MintSuccessful(
    address indexed minter,
    uint256 indexed tokenId,
    string tokenURI,
    uint256 price,
    bool isERC721
  );

  event PhotoPurchased(
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 quantity,
    uint256 price
  );

  event RoyaltyUpdated(
    uint256 indexed tokenId,
    address receiver,
    uint96 feeNumerator
  );

  event AIGenerationRequested(uint256 indexed tokenId, bytes32 requestId);
  event AIGenerationCompleted(
    uint256 indexed tokenId,
    uint256 indexed aiVariantId,
    string aiURI
  );
  event AIGenerationFailed(uint256 indexed tokenId, bytes error);
  event AIVariantMinted(
    uint256 indexed originalTokenId,
    uint256 indexed aiTokenId
  );

  // Event to log responses
  event Response(
    bytes32 indexed requestId,
    string character,
    bytes response,
    bytes err
  );

  event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);
  event FundsWithdrawn(
    address indexed receiver,
    uint256 ethAmount,
    uint256 usdcAmount
  );

  modifier onlyPhotoOwner(uint256 _tokenId) {
    // TODO: || msg.sender != multiplePhotoItems[_tokenId].owner
    if (msg.sender != s_purchaseState.photoItem[_tokenId].owner) {
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
    IPhotoFactoryEngine.EditionOwnership storage ownership = s_purchaseState
      .editionOwnership[_tokenId][_imageOwner];

    if (ownership.aiVariantIds.length >= ownership.copiesOwned) {
      revert PhotoFactoryEngine__ExceededAiVariantAllowed();
    }
    _;
  }

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
  )
    FunctionsClient(_routerAddress)
    ConfirmedOwner(_engineOwner)
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
    s_purchaseState.itemsSold = 0;
    s_priceFeed = AggregatorV2V3Interface(_priceFeed);
    s_purchaseState.usdcAddress = _usdcAddress;
  }

  //TODO: when mint fails, does variable changed in the function call restore to previoius state
  function mint(
    string memory _tokenURI,
    string memory _description,
    string memory _photoName,
    uint256 _price,
    uint256 _editionSize
  ) external nonReentrant onlyOwner {
    if (_editionSize < 1) {
      revert PhotoFactoryEngine__InvalidEditionSize();
    }

    uint256 tokenId = s_photoCounter + 1;
    s_photoCounter = tokenId;

    if (_exists(tokenId)) {
      revert PhotoFactory721__TokenAlreadyExists();
    }

    if (_editionSize == 1) {
      s_purchaseState.photoItem[tokenId] = IPhotoFactoryEngine.PhotoItem({
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
        s_purchaseState.photoItem[tokenId].minted = true;
        emit MintSuccessful(owner(), tokenId, _tokenURI, _price, true);
      } catch {
        revert PhotoFactoryEngine__MintFailed();
      }
    } else {
      s_purchaseState.multiplePhotoItems[tokenId] = IPhotoFactoryEngine
        .MultiplePhotoItems({
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

      try
        factory1155.mint(
          address(this),
          tokenId,
          _editionSize,
          abi.encodePacked(_tokenURI)
        )
      {
        s_purchaseState.multiplePhotoItems[tokenId].minted = true;
        emit MintSuccessful(msg.sender, tokenId, _tokenURI, _price, false);
      } catch {
        revert PhotoFactoryEngine__MintFailed();
      }
    }
  }

  function purchase(
    uint256 _tokenId,
    uint256 _quantity,
    bool isUSDC
  ) public payable existingPhoto(_tokenId) nonReentrant {
    // Initial checks
    if (msg.value == 0 || _quantity == 0) {
      revert PhotoFactoryEngine__InvalidAmount();
    }

    uint256 price = getPrice(_tokenId);
    uint256 totalCost = price * _quantity;

    if (isUSDC) {
      PurchaseHandler.handleUSDCPayment(s_purchaseState, msg.sender, totalCost);
    } else {
      // Transfer funds to the owner
      if (msg.value < totalCost) revert PhotoFactoryEngine__InvalidAmount();
      PurchaseHandler.handleETHPayment(msg.value, totalCost, payable(owner()));
    }

    PurchaseHandler.processPurchase(
      s_purchaseState,
      factory721,
      factory1155,
      _tokenId,
      _quantity,
      msg.value,
      msg.sender
    );

    emit PhotoPurchased(_tokenId, msg.sender, _quantity, totalCost);
  }

  /**
   * @notice Sends an HTTP request for ai generated SVG variant
   * @param _tokenId The ID for the photoItem
   * @param _tokenURI the URI of the token
   * @return requestId The ID of the request
   */
  function generateAiVariant(
    uint256 _tokenId,
    string memory _tokenURI
  )
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
    s_lastRequestId = _sendRequest(
      req.encodeCBOR(),
      subscriptionId,
      gasLimit,
      donId
    );

    // Store the request ID to token ID mapping
    requestIdToTokenId[s_lastRequestId] = _tokenId;

    emit AIGenerationRequested(_tokenId, s_lastRequestId);

    return s_lastRequestId;
  }

  function mintAiVariant(
    uint256 _tokenId,
    uint256 _aiVariantId,
    address _sender
  )
    internal
    // existingPhoto(_tokenId)
    // onlyPhotoOwner(_tokenId)
    nonReentrant
  {
    // ensure AI generation is complete
    AiGeneratedVariant memory aiVariant = aiGeneratedVariant[_aiVariantId]; // get the AI variant

    if (
      aiGenerationInProgress[_tokenId] ||
      aiVariant.minted ||
      aiVariant.generationDate == 0 ||
      keccak256(abi.encodePacked(aiVariant.aiURI)) ==
      keccak256(abi.encodePacked(""))
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

      (bool isSingleEdition, bool isMultipleEdition) = PurchaseHandler
        .decidePhotoEdition(s_purchaseState, _tokenId);

      if (isSingleEdition) {
        s_purchaseState.photoItem[_tokenId].aiVariantTokenId = aiVariant
          .variantId;
      }

      if (isMultipleEdition) {
        s_purchaseState.multiplePhotoItems[_tokenId].aiVariantTokenIds.push(
          aiVariant.variantId
        );
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

  function tokenURI(
    uint256 _aiVariantTokenId,
    AiGeneratedVariant memory aiVariant
  ) public view returns (string memory) {
    // AiGeneratedVariant memory aiVariant = aiGeneratedVariant[_aiVariantTokenId];

    string memory imageURI = aiVariant.aiURI;
    string memory name;

    // sample description -  "description": "An NFT that reflects owners mood.", "attribures": [{"trait_type": "moodiness", "value":100}]
    string memory description = aiVariant.description;

    if (s_purchaseState.photoItem[aiVariant.originalImage].minted) {
      name = s_purchaseState.photoItem[aiVariant.originalImage].photoName;
    } else if (
      s_purchaseState.multiplePhotoItems[aiVariant.originalImage].minted
    ) {
      name = s_purchaseState
        .multiplePhotoItems[aiVariant.originalImage]
        .photoName;
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
              '{"name": "',
              name,
              '", "description": "',
              description,
              '", "image": "',
              imageURI,
              '"  }'
            )
          )
        )
      )
    );

    return tokenMetadata;
  }

  // Verify how to withdraw funds from all contracts
  function withdrawFunds() public onlyOwner {
    uint256 ethBalance = address(this).balance;
    uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));

    if (ethBalance == 0 && usdcBalance == 0) {
      revert PhotoFactoryEngine__NoFundsToWithdraw();
    }

    if (ethBalance > 0) {
      (bool success, ) = payable(owner()).call{value: ethBalance}("");

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
  function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) internal override {
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
  function getAiGenerationStatus(
    uint256 _tokenId
  )
    public
    view
    returns (
      bool inProgress,
      bool completed,
      string memory aiUri,
      uint256 generationDate
    )
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

  function _baseURI() public pure returns (string memory) {
    return "data:application/json;base64";
  }

  function _processETHPayment(uint256 amount) private {
    (bool success, ) = payable(owner()).call{value: amount}("");
    if (!success) revert PhotoFactoryEngine__TransactionFailed();
  }

  function _updateBuyersList(address buyer) private {
    if (!_isNewBuyer(buyer)) {
      s_purchaseState.buyers.push(buyer);
    }
  }

  function _exists(uint256 tokenId) private view returns (bool) {
    bool exists = false;

    if (
      s_purchaseState.photoItem[tokenId].minted == true ||
      s_purchaseState.multiplePhotoItems[tokenId].minted == true
    ) {
      exists = true;
    }

    return exists;
  }

  function _isNewBuyer(address _address) private view returns (bool) {
    for (uint256 i = 0; i < s_purchaseState.buyers.length; i++) {
      if (s_purchaseState.buyers[i] == _address) {
        return true;
      }
    }
    return false;
  }

  function updatePrice(
    uint256 _tokenId,
    uint256 _newPrice
  ) public payable onlyOwner existingPhoto(_tokenId) {
    // implement price update for multiple photos as well, - when no buyer**
    s_purchaseState.photoItem[_tokenId].price = _newPrice;
    emit PriceUpdated(_tokenId, _newPrice);
  }

  function getPrice(uint256 _tokenId) public view returns (uint256) {
    (bool isSingleEdition, bool isMultipleEdition) = PurchaseHandler
      .decidePhotoEdition(s_purchaseState, _tokenId);
    uint256 price;

    if (isSingleEdition) {
      price = s_purchaseState.photoItem[_tokenId].price;
    }

    if (isMultipleEdition) {
      price = s_purchaseState.multiplePhotoItems[_tokenId].price;
    }

    if (price == 0) {
      revert PhotoFactoryEngine__TransactionFailed();
    }

    return price;
  }

  function verifyMint(uint256 tokenId) public view returns (bool) {
    bool minted = false;
    if (
      s_purchaseState.photoItem[tokenId].minted == true ||
      s_purchaseState.multiplePhotoItems[tokenId].minted
    ) {
      minted = true;
    }

    return minted;
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

  function getPhotoCounter() public view returns (uint256) {
    return s_photoCounter;
  }

  // improve
  function getItemsSold() public view returns (uint256) {
    return s_purchaseState.itemsSold;
  }

  function getBuyers() public view returns (address[] memory) {
    return s_purchaseState.buyers;
  }

  function getEditionOwnership(
    uint256 _tokenId,
    address _owner
  ) public view returns (IPhotoFactoryEngine.EditionOwnership memory) {
    return s_purchaseState.editionOwnership[_tokenId][_owner];
  }

  function getUserEditionCount(
    address _user,
    uint256 _tokenId
  ) public view returns (uint256) {
    return s_purchaseState.userEditionCount[_user][_tokenId];
  }

  function getVersion() public pure returns (uint256) {
    return VERSION;
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  // TODO: Implement batch purchase - draft state
  // function batchPurchase(uint256[] calldata tokenIds, uint256[] calldata quantities) external payable {
  //     require(tokenIds.length == quantities.length, "Length mismatch");
  //     for (uint256 i = 0; i < tokenIds.length; i++) {
  //         purchase(tokenIds[i], quantities[i]);
  //     }
  // }

  function batchUpdatePrice(
    uint256[] calldata tokenIds,
    uint256[] calldata prices
  ) external onlyOwner {
    require(tokenIds.length == prices.length, "Length mismatch");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      updatePrice(tokenIds[i], prices[i]);
    }
  }

  function getMultiplePhotoItems(
    uint256 _tokenId
  ) public view returns (IPhotoFactoryEngine.MultiplePhotoItems memory) {
    IPhotoFactoryEngine.MultiplePhotoItems memory photo = s_purchaseState
      .multiplePhotoItems[_tokenId];

    return photo;
  }

  function getPhotoItem(
    uint256 tokenId
  ) public view returns (IPhotoFactoryEngine.PhotoItem memory) {
    return s_purchaseState.photoItem[tokenId];
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}
