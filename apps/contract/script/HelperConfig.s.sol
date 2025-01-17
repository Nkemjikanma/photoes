// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol"; //
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address routerAddress;
        bytes32 donId;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint256 deployerKey;
        address priceFeed;
        address usdcAddress;
    }
    // mock data for MockV3Aggregator

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // Router address
    address router_base_testnet = 0xf9B8fc078197181C841c296C876945aaa425B278;
    address router_base_mainnet = 0xf9B8fc078197181C841c296C876945aaa425B278;

    //Callback gas limit
    uint32 gasLimit = 300000;

    // DonId
    bytes32 donID_base_mainnet = 0x66756e2d626173652d6d61696e6e65742d310000000000000000000000000000;
    bytes32 donID_base_testnet = 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000;

    address base_sepolia_pricefeed = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
    address base_mainnet_pricefeed = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;

    address usdc_base = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address usdc_test = makeAddr("usdcAddress");

    // Subscription Id
    uint64 subscriptionId = 4129;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 84532) {
            // base sepolia testnet
            activeNetworkConfig = getBaseSepoliaEthConfig();
        } else if (block.chainid == 8453) {
            activeNetworkConfig = getBaseMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getBaseSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: router_base_testnet,
            donId: donID_base_testnet,
            subscriptionId: subscriptionId,
            callbackGasLimit: gasLimit,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            priceFeed: base_sepolia_pricefeed,
            usdcAddress: usdc_test
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.routerAddress != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockAggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            routerAddress: address(0),
            donId: bytes32(0),
            subscriptionId: 0,
            callbackGasLimit: gasLimit,
            deployerKey: DEFAULT_ANVIL_KEY,
            priceFeed: address(mockAggregator),
            usdcAddress: usdc_test
        });

        return anvilConfig;
    }

    function getBaseMainnetEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: router_base_mainnet,
            donId: donID_base_mainnet,
            subscriptionId: subscriptionId,
            callbackGasLimit: gasLimit,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            priceFeed: base_mainnet_pricefeed,
            usdcAddress: usdc_base
        });
    }
}
