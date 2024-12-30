// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployPhotoFactory} from "../../script/DeployPhotoFactory.s.sol";
import {PhotoFactory721} from "../../src/PhotoFactory721.sol";
import {PhotoFactory1155} from "../../src/PhotoFactory1155.sol";
import {PhotoFactoryEngine} from "../../src/PhotoFactoryEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract PhotoFactoryEngineTest is Test {
  DeployPhotoFactory deployer;
  PhotoFactoryEngine engine;
  PhotoFactory721 factory721;
  PhotoFactory1155 factory1155;
  HelperConfig helperConfig;

  address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Use a specific address for the owner

  function setUp() public {
    deployer = new DeployPhotoFactory();

    (engine, factory721, factory1155, helperConfig) = deployer.run();
  }

  function testDeployment() public view {
    assert(address(engine) != address(0));
    assert(address(factory721) != address(0));
    assert(address(factory1155) != address(0));
  }

  function testMintSingleEdition() public {
    string memory tokenURI = "ipfs://example";
    string memory description = "A shot in the wild";
    string memory photoName = "Lion smile";
    uint256 price = 0.08 ether;
    uint256 editionSize = 1;

    vm.deal(owner, 1 ether);
    vm.prank(owner);

    engine.mint(tokenURI, description, photoName, price, editionSize);

    assertPhotoBasicInfo(1, tokenURI, photoName, description, editionSize);
    assertPhotoOwnershipInfo(1, owner, price);
    assertPhotoMintingStatus(1, true, false, 0);
  }

  // Helper functions to check different aspects of the minted photo
  function assertPhotoBasicInfo(
    uint256 expectedTokenId,
    string memory expectedTokenURI,
    string memory expectedName,
    string memory expectedDescription,
    uint256 expectedSize
  ) private view {
    (
      uint256 tokenId,
      string memory name,
      uint256 size,
      string memory uri,
      string memory desc,
      ,
      ,
      ,
      ,

    ) = engine.photoItem(1);

    assertEq(tokenId, expectedTokenId);
    assertEq(name, expectedName);
    assertEq(size, expectedSize);
    assertEq(uri, expectedTokenURI);
    assertEq(desc, expectedDescription);
  }

  function assertPhotoOwnershipInfo(
    uint256 tokenId,
    address expectedOwner,
    uint256 expectedPrice
  ) private view {
    (, , , , , address photoOwner, , , uint256 price, ) = engine.photoItem(
      tokenId
    );
    assertEq(photoOwner, expectedOwner);
    assertEq(price, expectedPrice);
  }

  function assertPhotoMintingStatus(
    uint256 tokenId,
    bool expectedMinted,
    bool expectedPurchased,
    uint256 expectedAiVariantTokenId
  ) private view {
    (
      ,
      ,
      ,
      ,
      ,
      ,
      bool minted,
      bool purchased,
      ,
      uint256 aiVariantTokenId
    ) = engine.photoItem(tokenId);
    assertEq(minted, expectedMinted);
    assertEq(purchased, expectedPurchased);
    assertEq(aiVariantTokenId, expectedAiVariantTokenId);
  }

  // ***** test multiple mint ****//
  function testMintMultipleEdition() public {
    string memory tokenURI = "ipfs://example";
    string memory description = "A shot in the wild";
    string memory photoName = "Lion smile";
    uint256 price = 0.08 ether;
    uint256 editionSize = 20;

    vm.deal(owner, 1 ether);
    vm.prank(owner);

    engine.mint(tokenURI, description, photoName, price, editionSize);

    assertMultiplePhotoItemBasicInfo(
      1,
      tokenURI,
      photoName,
      description,
      editionSize
    );
    // assertMultiplePhotoItemOwnershipInfo(1, owner, price);
    // assertMultiplePhotoItemMintingStatus(1, true, false, 0);
  }

  // Helper functions to check different aspects of the minted photo
  function assertMultiplePhotoItemBasicInfo(
    uint256 expectedTokenId,
    string memory expectedTokenURI,
    string memory expectedName,
    string memory expectedDescription,
    uint256 expectedSize
  ) private view {
    (
      uint256 tokenId,
      string memory name,
      uint256 size,
      string memory uri,
      string memory desc,
      ,
      ,

    ) = engine.multiplePhotoItem(1);

    assertEq(tokenId, expectedTokenId);
    assertEq(name, expectedName);
    assertEq(size, expectedSize);
    assertEq(uri, expectedTokenURI);
    assertEq(desc, expectedDescription);
    //   assertEq(owners[0], expectedOwner); // Assuming the first owner is the expected owner
    //   assertEq(price, expectedPrice);
  }

  function assertMultiplePhotoItemOwnershipInfo(
    uint256 tokenId,
    address expectedOwner,
    uint256 expectedPrice
  ) private view {
    (
      uint256 tokenId,
      string memory name,
      uint256 size,
      string memory uri,
      string memory desc,
      address[] memory owners,
      uint256 price,

    ) = engine.multiplePhotoItem(1);
    assertEq(owners[0], expectedOwner); // Assuming the first owner is the expected owner
    assertEq(price, expectedPrice);
  }

  // function assertMultiplePhotoItemMintingStatus(
  //   uint256 tokenId,
  //   bool expectedMinted,
  //   bool expectedPurchased,
  //   uint256 expectedAiVariantTokenId
  // ) private view {
  //   (
  //     ,
  //     ,
  //     ,
  //     ,
  //     ,
  //     ,
  //     bool minted,
  //     uint256 totalPurchased,
  //     uint256[] memory aiVariantTokenIds
  //   ) = engine.multiplePhotoItem(tokenId);
  //   assertEq(minted, expectedMinted);
  //   assertEq(totalPurchased, expectedPurchased);
  //   assertEq(aiVariantTokenIds.length, expectedAiVariantTokenId);
  // }
}
