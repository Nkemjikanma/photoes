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
    error PhotoFactoryEngine__ExceededEditionSize(uint256 editionSize, uint256 remainingEditions);

    event PurchaseCompleted(uint256 indexed tokenId, address indexed buyer, uint256 quantity, uint256 price);

    struct PurchaseState {
        address usdcAddress;
        uint256 itemsSold;
        mapping(uint256 => IPhotoFactoryEngine.PhotoItem) photoItem;
        mapping(uint256 => IPhotoFactoryEngine.MultiplePhotoItems) multiplePhotoItems;
        mapping(uint256 => mapping(address => IPhotoFactoryEngine.EditionOwnership)) editionOwnership; // Track who owns how many copies of each edition - tokenid > address > editionOwnership
        mapping(address => mapping(uint256 => uint256)) userEditionCount; // user => tokenId => number of editions owned
        address[] buyers;
    }

    enum PaymentType {
        ETH,
        USDC
    }

    /// @notice Processes a purchase transaction
    /// @param _state Current state of the purchase system
    /// @param _factory721 ERC721 contract instance
    /// @param _factory1155 ERC1155 contract instance
    /// @param _tokenId ID of the token being purchased
    /// @param _quantity Number of tokens to purchase
    /// @param _value Amount of ETH/USDC sent
    /// @param _sender Address of the buyer
    function processPurchase(
        PurchaseState storage _state,
        PhotoFactory721 _factory721,
        PhotoFactory1155 _factory1155,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _value,
        address _sender
    ) external {
        if (_sender == address(0)) revert("Invalid sender address");
        if (address(_factory721) == address(0)) {
            revert("Invalid factory721 address");
        }
        if (address(_factory1155) == address(0)) {
            revert("Invalid factory1155 address");
        }

        (bool isSingleEdition, bool isMultipleEdition) = decidePhotoEdition(_state, _tokenId);

        if (isSingleEdition) {
            purchaseSingleEdition(_state, _factory721, _tokenId, _sender);
        } else if (isMultipleEdition) {
            purchaseMultipleEdition(
                _state,
                _factory1155,
                _state.multiplePhotoItems[_tokenId], // TODO: what is this?
                _quantity,
                _tokenId,
                _sender
            );
        }

        updateBuyersList(_state, _sender);
        unchecked {
            _state.itemsSold++;
        }

        emit PurchaseCompleted(_tokenId, _sender, _quantity, _value);
    }

    function purchaseSingleEdition(
        PurchaseState storage _state,
        PhotoFactory721 _factory721,
        uint256 _tokenId,
        address _sender
    ) private {
        // Checks-Effects-Interactions
        IPhotoFactoryEngine.PhotoItem storage photo = _state.photoItem[_tokenId];

        // checks
        if (photo.purchased || photo.owner == _sender) {
            revert PhotoFactoryEngine__AlreadyBought();
        }

        // effects - change states
        photo.owner = _sender;
        photo.purchased = true;

        _state.editionOwnership[_tokenId][_sender] =
            IPhotoFactoryEngine.EditionOwnership({copiesOwned: 1, aiVariantIds: new uint256[](0), canMintAi: true});

        _state.userEditionCount[_sender][_tokenId] = 1;

        // // Generate AI variant
        // generateAiVariant(_tokenId, _photo.tokenURI);

        // interactions - external call
        _factory721.transferERC721(address(this), _sender, _tokenId);
    }

    function purchaseMultipleEdition(
        PurchaseState storage _state,
        PhotoFactory1155 _factory1155,
        IPhotoFactoryEngine.MultiplePhotoItems storage _photo,
        uint256 _quantity,
        uint256 _tokenId,
        address _sender
    ) private {
        uint256 remainingEditions = _photo.editionSize - _photo.totalPurchased;

        // checks
        if (_quantity == 0 || _quantity > remainingEditions) {
            revert PhotoFactoryEngine__ExceededEditionSize(_photo.editionSize, remainingEditions);
        }
        //effects - update ownership
        IPhotoFactoryEngine.EditionOwnership storage ownership = _state.editionOwnership[_tokenId][_sender];
        ownership.copiesOwned += _quantity;
        ownership.canMintAi = true;
        if (ownership.aiVariantIds.length == 0) {
            ownership.aiVariantIds = new uint256[](0);
        }

        // TODO: // create a modifier/function to check the number of ai variants that users with multiple editions can generate

        _state.userEditionCount[_sender][_tokenId] += _quantity; // track how many editions

        _photo.totalPurchased += _quantity;
        _photo.owners.push(_sender);

        // // Generate AI variant
        // generateAiVariant(_tokenId, _photo.tokenURI);

        _state.itemsSold++;

        //interactions
        _factory1155.transferERC1155(address(this), _sender, _tokenId, _quantity, "");
    }

    function handleUSDCPayment(PurchaseState storage _state, address _buyer, uint256 _amount) external {
        IERC20 usdc = IERC20(_state.usdcAddress);

        if (usdc.balanceOf(_buyer) < _amount) {
            revert PhotoFactoryEngine__AmountTooLow();
        }

        bool success = usdc.transferFrom(_buyer, address(this), _amount);
        if (!success) revert PhotoFactoryEngine__TransactionFailed();
    }

    function handleETHPayment(uint256 _sent, uint256 _totalCost, address payable _recipient) external {
        if (_sent < _totalCost) revert PhotoFactoryEngine__AmountTooLow();
        _processETHPayment(_sent, _recipient);
    }

    function decidePhotoEdition(PurchaseState storage _state, uint256 _tokenId) public view returns (bool, bool) {
        bool isSingleEdition = _state.photoItem[_tokenId].editionSize == 1;
        bool isMultipleEdition = _state.multiplePhotoItems[_tokenId].editionSize > 1;

        return (isSingleEdition, isMultipleEdition);
    }

    function updateBuyersList(PurchaseState storage _state, address _buyer) private {
        if (isNewBuyer(_state, _buyer)) {
            _state.buyers.push(_buyer);
        }
    }

    function isNewBuyer(PurchaseState storage _state, address _buyer) private view returns (bool) {
        uint256 length = _state.buyers.length;
        for (uint256 i = 0; i < length; i++) {
            // Cache array length
            if (_state.buyers[i] == _buyer) {
                return false;
            }
        }
        return true;
    }

    function _processETHPayment(uint256 _amount, address payable _recipient) private {
        (bool success,) = _recipient.call{value: _amount}("");
        if (!success) revert PhotoFactoryEngine__TransactionFailed();
    }
}
