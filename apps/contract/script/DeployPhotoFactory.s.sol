// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {PhotoFactoryEngine} from "../src/PhotoFactoryEngine.sol";
import {PhotoFactory721} from "../src/PhotoFactory721.sol";
import {PhotoFactory1155} from "../src/PhotoFactory1155.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployPhotoFactory is Script {
    address owner = vm.envAddress("DEV_ADDRESS");

    function run() external returns (PhotoFactoryEngine, PhotoFactory721, PhotoFactory1155, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address routerAddress, bytes32 donId, uint64 subscriptionId, uint32 callbackGasLimit, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        PhotoFactory721 factory721 = new PhotoFactory721(owner);
        PhotoFactory1155 factory1155 = new PhotoFactory1155(owner);

        PhotoFactoryEngine engine = new PhotoFactoryEngine(
            address(factory721), address(factory1155), subscriptionId, routerAddress, donId, callbackGasLimit, owner
        );

        factory721.transferOwnership(address(engine));
        factory1155.transferOwnership(address(engine));

        vm.stopBroadcast();

        return (engine, factory721, factory1155, helperConfig);
    }
}
