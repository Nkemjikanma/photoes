// SPDX-License-Identifier: MIT
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPhotoFactoryEngine} from "../interfaces/IPhotoFactoryEngine.sol";
import {PhotoFactory721} from "../PhotoFactory721.sol";
import {PhotoFactory1155} from "../PhotoFactory1155.sol";

/* @title PurchaseHandler Library
 * @notice Handles purchase logic for Nkemjika's NFTs
 * @dev Manages both ERC721 and ERC1155 purchases
 */
pragma solidity 0.8.27;

library PurchaseHandler {
  error InvalidAddress();
  error InvalidQuantity();
  error InvalidPaymentAmount();
  error TransferFailed();
  error PhotoFactoryEngine__AmountTooLow();
  error PhotoFactoryEngine__TransactionFailed();
  error PhotoFactoryEngine__AlreadyBought();
  error InvalidEditionType();
  error PhotoFactoryEngine__ExceededEditionSize(
    uint256 editionSize,
    uint256 remainingEditions
  );

  event PurchaseCompleted(
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 quantity,
    uint256 price,
    IPhotoFactoryEngine.EditionType editionType
  );

  struct PurchaseState {
    address usdcAddress;
    uint256 itemsSold;
    mapping(uint256 => IPhotoFactoryEngine.Photo) photos;
    mapping(uint256 => mapping(address => IPhotoFactoryEngine.PhotoOwnership)) photoOwnerships; // Track who owns how many copies of each edition - tokenid > address > editionOwnership
    mapping(address => mapping(uint256 => uint256)) userEditionCount; // user => tokenId => number of editions owned
    mapping(uint256 => IPhotoFactoryEngine.Collection) collections;
    address[] buyers;
  }

  enum PaymentType {
    ETH,
    USDC
  }

  /**
   * @notice Processes a purchase transaction
   * @param _state Current state of the purchase system
   * @param _factory721 ERC721 contract instance
   * @param _factory1155 ERC1155 contract instance
   * @param _photoId ID of the token being purchased
   * @param _quantity Number of tokens to purchase
   * @param _value Amount of ETH/USDC sent
   * @param _sender Buyer's address
   */
  function processPurchase(
    PurchaseState storage _state,
    PhotoFactory721 _factory721,
    PhotoFactory1155 _factory1155,
    uint256 _photoId,
    uint256 _quantity,
    uint256 _value,
    address _sender
  ) external {
    if (_sender == address(0)) revert InvalidAddress();
    if (address(_factory721) == address(0)) {
      revert InvalidAddress();
    }
    if (address(_factory1155) == address(0)) {
      revert InvalidAddress();
    }

    IPhotoFactoryEngine.Photo storage photo = _state.photos[_photoId];

    if (photo.editionType == IPhotoFactoryEngine.EditionType.Single) {
      _purchaseSingleEdition(_state, _factory721, photo, _photoId, _sender);
    } else if (isMultipleEdition) {
      _purchaseMultipleEdition(
        _state,
        _factory1155,
        photo,
        _photoId,
        _quantity,
        _sender
      );
    }

    _updateBuyersList(_state, _sender);
    unchecked {
      _state.itemsSold++;
      photo.totalMinted += _quantity;
    }

    emit PurchaseCompleted(
      _photoId,
      _sender,
      _quantity,
      _value,
      photo.editionType
    );
  }

  /**
   * @notice Process purchase of a single edition photo
   * @param _state Current state of the purchase system
   * @param _factory721 ERC721 contract instance
   * @param _photo Photo being purchased
   * @param _photoId ID of the photo being purchased
   * @param _sender Buyer's address
   */
  function purchaseSingleEdition(
    PurchaseState storage _state,
    PhotoFactory721 _factory721,
    IPhotoFactoryEngine.Photo storage _photo,
    uint256 _photoId,
    address _sender
  ) private {
    // checks
    // if (_photo.totalMinted > 0) {
    //   revert PhotoFactoryEngine__AlreadyBought();
    // }

    // if (photo.purchased || photo.owner == _sender) {
    //   revert PhotoFactoryEngine__AlreadyBought();
    // }

    // effects - change states
    // photo.owner = _sender;
    // photo.purchased = true;
    IPhotoFactoryEngine.PhotoOwnership storage ownership = _state
      .photoOwnerships[_photoId][_sender];

    ownership.photoId = _photoId;
    ownership.owner = _sender;
    ownership.quantity = 1;
    ownership.purchaseDate = block.timestamp;
    ownership.aiVariantIds = new uint256[](0);

    // // Generate AI variant
    // generateAiVariant(_tokenId, _photo.tokenURI);

    // interactions - external call
    _factory721.transferERC721(address(this), _sender, _photoId);
  }

  /**
   * @notice Process purchase of a multiple edition photo
   * @param _state Current state of the purchase system
   * @param _factory1155 ERC1155 contract instance
   * @param _photo Photo being purchased
   * @param _photoId ID of the photo being purchased
   * @param _sender Buyer's address
   */
  function purchaseMultipleEdition(
    PurchaseState storage _state,
    PhotoFactory1155 _factory1155,
    IPhotoFactoryEngine.MultiplePhotoItems storage _photo,
    uint256 _photoId,
    uint256 _quantity,
    address _sender
  ) private {
    uint256 remainingEditions = _photo.editionSize - _photo.totalPurchased;

    // checks
    if (_quantity == 0 || _quantity > remainingEditions) {
      revert PhotoFactoryEngine__ExceededEditionSize(
        _photo.editionSize,
        remainingEditions
      );
    }

    //effects - update ownership
    IPhotoFactoryEngine.PhotoOwnership storage ownership = _state
      .photoOwnerships[_photoId][_sender];

    if (ownership.purchaseDate == 0) {
      // New ownership
      ownership.photoId = _photoId;
      ownership.owner = _sender;
      ownership.quantity = _quantity;
      ownership.purchaseDate = block.timestamp;
      ownership.aiVariantIds = new uint256[](0);
    } else {
      // Existing ownership
      ownership.quantity += _quantity;
    }

    // TODO: // create a modifier/function to check the number of ai variants that users with multiple editions can generate

    _state.userEditionCount[_sender][_tokenId] += _quantity; // track how many editions

    _photo.totalPurchased += _quantity;
    _photo.owners.push(_sender);

    // // Generate AI variant
    // generateAiVariant(_tokenId, _photo.tokenURI);

    _state.itemsSold++;

    //interactions
    _factory1155.transferERC1155(
      address(this),
      _sender,
      _tokenId,
      _quantity,
      ""
    );
  }

  /**
   * @notice Handle USDC payments
   * @param _state Current state of the purchase system
   * @param _buyer Buyer's address
   * @param _amount Amount of USDC
   */
  function handleUSDCPayment(
    PurchaseState storage _state,
    address _buyer,
    uint256 _amount
  ) external {
    IERC20 usdc = IERC20(_state.usdcAddress);

    if (usdc.balanceOf(_buyer) < _amount) {
      revert PhotoFactoryEngine__AmountTooLow();
    }

    bool success = usdc.transferFrom(_buyer, address(this), _amount);
    if (!success) revert PhotoFactoryEngine__TransactionFailed();
  }

  /**
   * @notice Handle ETH payments
   * @param _sent Amount of ETH sent
   * @param _totalCost Total cost of the Purchase
   * @param _recipient Receipient of payment
   */
  function handleETHPayment(
    uint256 _sent,
    uint256 _totalCost,
    address payable _recipient
  ) external {
    if (_sent < _totalCost) revert PhotoFactoryEngine__AmountTooLow();
    _processETHPayment(_sent, _recipient);
  }

  /**
   * @notice Get photo price considering collection status
   */
  function getPhotoPrice(
    PurchaseState storage _state,
    uint256 _photoId
  ) public view returns (uint256) {
    IPhotoFactoryEngine.Photo storage photo = _state.photos[_photoId];

    if (photo.collectionId != 0) {
      return _state.collections[photo.collectionId].photos[_photoId].price;
    }

    return photo.price;
  }

  function decidePhotoEdition(
    PurchaseState storage _state,
    uint256 _tokenId
  ) public view returns (bool, bool) {
    bool isSingleEdition = _state.photoItem[_tokenId].editionType ==
      IPhotoFactoryEngine.EditionType.Single;
    bool isMultipleEdition = _state.multiplePhotoItems[_tokenId].editionSize ==
      IPhotoFactoryEngine.EditionType.Multiple;

    return (isSingleEdition, isMultipleEdition);
  }

  /**
   * @notice Update buyers list
   * @param _state Current state of the purchase system
   * @param _buyer Buyer's address
   */
  function _updateBuyersList(
    PurchaseState storage _state,
    address _buyer
  ) private {
    if (_isNewBuyer(_state, _buyer)) {
      _state.buyers.push(_buyer);
    }
  }

  /**
   * @notice Check if buyer is new
   * @param _state Current state of the purchase system
   * @param _buyer Buyer's address
   * @return bool
   */
  function _isNewBuyer(
    PurchaseState storage _state,
    address _buyer
  ) private view returns (bool) {
    uint256 length = _state.buyers.length;
    for (uint256 i = 0; i < length; i++) {
      // Cache array length
      if (_state.buyers[i] == _buyer) {
        return false;
      }
    }
    return true;
  }

  /**
   * @notice Process ETH payment
   * @param _amount Amount of ETH
   * @param _recipient Receipient of payment
   */
  function _processETHPayment(
    uint256 _amount,
    address payable _recipient
  ) private {
    (bool success, ) = _recipient.call{value: _amount}("");
    if (!success) revert PhotoFactoryEngine__TransactionFailed();
  }
}
