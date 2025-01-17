// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {PhotoFactoryEngine} from "../src/PhotoFactoryEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployPhotoFactory is Script {
    address owner = vm.envAddress("DEV_ADDRESS");

    function run() external returns (PhotoFactoryEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address routerAddress,
            bytes32 donId,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            uint256 deployerKey,
            address priceFeed,
            address usdcAddress
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        PhotoFactoryEngine engine = new PhotoFactoryEngine(
            subscriptionId, routerAddress, donId, callbackGasLimit, owner, priceFeed, usdcAddress
        );

        vm.stopBroadcast();

        return (engine, helperConfig);
    }
}
