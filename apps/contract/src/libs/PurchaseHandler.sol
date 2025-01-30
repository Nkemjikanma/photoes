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
    error PhotoFactoryEngine__ExceededEditionSize(uint256 editionSize, uint256 remainingEditions);
    error PurchaseHandler__InsufficientAllowance();

    event PurchaseCompleted(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 quantity,
        uint256 price,
        IPhotoFactoryEngine.EditionType editionType
    );

    enum PaymentType {
        ETH,
        USDC
    }

    /**
     * @notice Handle USDC payments
     * @param _usdcAddress USDC address
     * @param _buyer Buyer's address
     * @param _amount Amount of USDC
     */
    function handleUSDCPayment(address _usdcAddress, address _buyer, uint256 _amount) external {
        IERC20 usdc = IERC20(_usdcAddress);

        uint256 allowance = usdc.allowance(_buyer, address(this));

        if (allowance < _amount) revert PurchaseHandler__InsufficientAllowance();

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
    function handleETHPayment(uint256 _sent, uint256 _totalCost, address payable _recipient) external {
        if (_sent < _totalCost) revert PhotoFactoryEngine__AmountTooLow();
        _processETHPayment(_sent, _recipient);
    }

    /**
     * @notice Process ETH payment
     * @param _amount Amount of ETH
     * @param _recipient Receipient of payment
     */
    function _processETHPayment(uint256 _amount, address payable _recipient) private {
        (bool success,) = _recipient.call{value: _amount}("");
        if (!success) revert PhotoFactoryEngine__TransactionFailed();
    }
}
