// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {console2} from "forge-std/console2.sol";

contract HelperConfigTest is Test {
    HelperConfig helperConfig;

    function setUp() public {
        helperConfig = new HelperConfig();
    }

    function testBaseSepoliaConfig() public {
        // Set chain ID to Base Sepolia
        vm.chainId(84532);

        // Mock the PRIVATE_KEY environment variable
        vm.setEnv("PRIVATE_KEY", "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef");

        HelperConfig.NetworkConfig memory config = helperConfig.getBaseSepoliaEthConfig();

        // Assert Base Sepolia specific values
        assertEq(config.routerAddress, 0xf9B8fc078197181C841c296C876945aaa425B278);
        assertEq(config.donId, 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000);
        assertEq(uint256(config.subscriptionId), 4129);
        assertEq(config.callbackGasLimit, 300000);
    }

    function testBaseMainnetConfig() public {
        // Set chain ID to Base Mainnet
        vm.chainId(8453);

        // Mock the PRIVATE_KEY environment variable
        vm.setEnv("PRIVATE_KEY", "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef");

        HelperConfig.NetworkConfig memory config = helperConfig.getBaseMainnetEthConfig();

        // Assert Base Mainnet specific values
        assertEq(config.routerAddress, 0xf9B8fc078197181C841c296C876945aaa425B278);
        assertEq(config.donId, 0x66756e2d626173652d6d61696e6e65742d310000000000000000000000000000);
        assertEq(uint256(config.subscriptionId), 4129);
        assertEq(config.callbackGasLimit, 300000);
    }

    // function testAnvilConfig() public {
    //   // Set chain ID to a non-Base chain (e.g., Anvil's default 31337)
    //   vm.chainId(31337);

    //   HelperConfig.NetworkConfig memory config = helperConfig
    //     .getOrCreateAnvilEthConfig();

    //   // Assert Anvil specific values
    //   assertEq(config.routerAddress, address(0));
    //   assertEq(config.donId, bytes32(0));
    //   assertEq(uint256(config.subscriptionId), 0);
    //   assertEq(config.callbackGasLimit, 300000);
    //   assertEq(
    //     config.deployerKey,
    //     0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    //   );
    // }

    // function testActiveNetworkConfigBaseSepolia() public {
    //   // Set chain ID to Base Sepolia
    //   vm.chainId(84532);

    //   // Create new HelperConfig to trigger constructor with this chain ID
    //   HelperConfig newConfig = new HelperConfig();

    //   HelperConfig.NetworkConfig memory config = newConfig.activeNetworkConfig();

    //   // Assert it's using Base Sepolia config
    //   assertEq(config.routerAddress, 0xf9B8fc078197181C841c296C876945aaa425B278);
    //   assertEq(
    //     config.donId,
    //     0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000
    //   );
    // }

    // function testActiveNetworkConfigBaseMainnet() public {
    //   // Set chain ID to Base Mainnet
    //   vm.chainId(8453);

    //   // Create new HelperConfig to trigger constructor with this chain ID
    //   HelperConfig newConfig = new HelperConfig();

    //   HelperConfig.NetworkConfig memory config = newConfig.activeNetworkConfig();

    //   // Assert it's using Base Mainnet config
    //   assertEq(config.routerAddress, 0xf9B8fc078197181C841c296C876945aaa425B278);
    //   assertEq(
    //     config.donId,
    //     0x66756e2d626173652d6d61696e6e65742d310000000000000000000000000000
    //   );
    // }

    // function testActiveNetworkConfigAnvil() public {
    //   // Set chain ID to Anvil
    //   vm.chainId(31337);

    //   // Create new HelperConfig to trigger constructor with this chain ID
    //   HelperConfig newConfig = new HelperConfig();

    //   HelperConfig.NetworkConfig memory config = newConfig.activeNetworkConfig();

    //   // Assert it's using Anvil config
    //   assertEq(config.routerAddress, address(0));
    //   assertEq(config.donId, bytes32(0));
    // }

    // function testEnvironmentVariableInSepolia() public {
    //   // Set chain ID to Base Sepolia
    //   vm.chainId(84532);

    //   // Mock environment variable
    //   vm.setEnv(
    //     "PRIVATE_KEY",
    //     "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    //   );

    //   HelperConfig.NetworkConfig memory config = helperConfig
    //     .getBaseSepoliaEthConfig();

    //   // Assert the private key was correctly loaded
    //   assertEq(
    //     config.deployerKey,
    //     uint256(
    //       0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
    //     )
    //   );
    // }

    // function testGetActiveNetworkConfigMultipleTimes() public {
    //   // Test that calling getOrCreateAnvilEthConfig multiple times returns same config
    //   vm.chainId(31337);

    //   HelperConfig.NetworkConfig memory config1 = helperConfig
    //     .getOrCreateAnvilEthConfig();
    //   HelperConfig.NetworkConfig memory config2 = helperConfig
    //     .getOrCreateAnvilEthConfig();

    //   assertEq(config1.routerAddress, config2.routerAddress);
    //   assertEq(config1.donId, config2.donId);
    //   assertEq(config1.subscriptionId, config2.subscriptionId);
    // }
}
