// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {DeployPhotoFactory} from "../../script/DeployPhotoFactory.s.sol";
import {PhotoFactory721} from "../../src/PhotoFactory721.sol";
import {PhotoFactory1155} from "../../src/PhotoFactory1155.sol";
import {PhotoFactoryEngine} from "../../src/PhotoFactoryEngine.sol";
import {IPhotoFactoryEngine} from "../../src/IPhotoFactoryEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract PhotoFactoryEngineTest is Test {
  DeployPhotoFactory deployer;
  PhotoFactoryEngine engine;
  PhotoFactory721 factory721;
  PhotoFactory1155 factory1155;
  HelperConfig helperConfig;

  address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Use a specific address for the owner
  address buyer = makeAddr("buyer");

  function setUp() public {
    deployer = new DeployPhotoFactory();

    (engine, factory721, factory1155, helperConfig) = deployer.run();
    // var () = helperConfig.activeNetworkConfig();
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
    IPhotoFactoryEngine.PhotoItem memory photoItem = engine.getPhotoItem(1);

    assertEq(photoItem.tokenId, expectedTokenId);
    assertEq(photoItem.photoName, expectedName);
    assertEq(photoItem.editionSize, expectedSize);
    assertEq(photoItem.tokenURI, expectedTokenURI);
    assertEq(photoItem.description, expectedDescription);
  }

  function assertPhotoOwnershipInfo(
    uint256 tokenId,
    address expectedOwner,
    uint256 expectedPrice
  ) private view {
    IPhotoFactoryEngine.PhotoItem memory photoItem = engine.getPhotoItem(
      tokenId
    );
    assertEq(photoItem.owner, expectedOwner);
    assertEq(photoItem.price, expectedPrice);
  }

  function assertPhotoMintingStatus(
    uint256 tokenId,
    bool expectedMinted,
    bool expectedPurchased,
    uint256 expectedAiVariantTokenId
  ) private view {
    IPhotoFactoryEngine.PhotoItem memory photoItem = engine.getPhotoItem(
      tokenId
    );
    assertEq(photoItem.minted, expectedMinted);
    assertEq(photoItem.purchased, expectedPurchased);
    assertEq(photoItem.aiVariantTokenId, expectedAiVariantTokenId);
  }

  function testPurchaseSingleEdition() public {
    // First mint a single edition
    string memory tokenURI = "ipfs://example";
    string memory description = "A shot in the wild";
    string memory photoName = "Lion smile";
    uint256 price = 0.08 ether;
    uint256 editionSize = 1;

    // Mint as owner
    vm.deal(owner, 1 ether);
    vm.prank(owner);
    engine.mint(tokenURI, description, photoName, price, editionSize);

    // buyer purchase
    uint256 tokenId = 1;
    uint256 quantity = 1;

    vm.deal(buyer, 3 ether);
    vm.prank(buyer);

    engine.purchase{value: price}(tokenId, quantity);

    // Get the photo details after purchase
    IPhotoFactoryEngine.PhotoItem memory photoItem = engine.getPhotoItem(1);

    // Assert the purchase results
    assertEq(photoItem.tokenId, 1);
    assertEq(photoItem.photoName, photoName);
    assertEq(photoItem.editionSize, editionSize);
    assertEq(photoItem.tokenURI, tokenURI);
    assertEq(photoItem.description, description);
    assertEq(photoItem.owner, buyer); // Owner should now be the buyer
    assertEq(photoItem.minted, true);
    assertEq(photoItem.purchased, true); // Should be marked as purchased
    assertEq(photoItem.price, price);
    assertEq(photoItem.aiVariantTokenId, 0);

    // check number of items sold
    uint256 itemsSold = engine.getItemsSold();
    assertEq(itemsSold, 1);

    // Verify buyer is in the buyers list
    address[] memory buyersList = engine.getBuyers();
    assertEq(buyersList[0], buyer);

    // Check EditionOwnership
    (uint256 copiesOwned, bool canMintAi) = engine.editionOwnership(1, buyer);

    // Assert EditionOwnership
    assertEq(copiesOwned, 1, "Should own 1 copy");
    assertTrue(canMintAi, "Should be able to mint AI variants");

    // Check userEditionCount
    uint256 editionCount = engine.userEditionCount(buyer, 1);
    assertEq(editionCount, 1, "User should own 1 edition");
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

    // console2.log("Owner address:", owner);
    // console2.log("Factory1155 address:", address(factory1155));
    // console2.log("Engine address:", address(engine));

    // try engine.mint(tokenURI, description, photoName, price, editionSize) {
    //   console2.log("Mint successful");
    // } catch Error(string memory reason) {
    //   console2.log("Mint failed:", reason);
    // }

    engine.mint(tokenURI, description, photoName, price, editionSize);

    // Get the full struct data
    IPhotoFactoryEngine.MultiplePhotoItem memory photo = engine
      .getMultiplePhotoItem(1);

    // Assert all fields
    assertEq(photo.tokenId, 1);
    assertEq(photo.photoName, photoName);
    assertEq(photo.editionSize, editionSize);
    assertEq(photo.tokenURI, tokenURI);
    assertEq(photo.description, description);
    assertEq(photo.price, price);
    assertEq(photo.minted, true);
    assertEq(photo.totalPurchased, 0);
  }

  function testPurchaseMultipleEdition() public {
    string memory tokenURI = "ipfs://example";
    string memory description = "A shot in the wild";
    string memory photoName = "Lion smile";
    uint256 price = 0.01 ether;
    uint256 editionSize = 20;
    uint256 purchaseQuantity = 5;

    vm.deal(owner, 5 ether);
    vm.prank(owner);

    engine.mint(tokenURI, description, photoName, price, editionSize);

    // buyer purchase
    uint256 tokenId = 1;
    uint256 purchaseAmount = price * purchaseQuantity;

    vm.deal(buyer, 10 ether);
    vm.prank(buyer);

    engine.purchase{value: purchaseAmount}(tokenId, purchaseQuantity);

    // Get the full struct data after purchase
    IPhotoFactoryEngine.MultiplePhotoItem memory photoItem = engine
      .getMultiplePhotoItem(1);

    // Assert basic information
    assertEq(photoItem.tokenId, tokenId, "Wrong token ID");
    assertEq(photoItem.photoName, photoName, "Wrong name");
    assertEq(photoItem.editionSize, editionSize, "Wrong edition size");
    assertEq(photoItem.tokenURI, tokenURI, "Wrong URI");
    assertEq(photoItem.description, description, "Wrong description");
    assertEq(photoItem.price, price, "Wrong price");
    assertEq(photoItem.minted, true, "Should be marked as minted");
    assertEq(
      photoItem.totalPurchased,
      purchaseQuantity,
      "Wrong number of purchases"
    );

    // Check owners array
    assertEq(photoItem.owners.length, 1, "Should have one owner");
    assertEq(photoItem.owners[0], buyer, "Wrong owner address");
    assertEq(
      photoItem.aiVariantTokenIds.length,
      0,
      "Should have no AI variants initially"
    );

    // Check EditionOwnership
    (uint256 copiesOwned, bool canMintAi) = engine.editionOwnership(
      tokenId,
      buyer
    );

    assertEq(copiesOwned, purchaseQuantity, "Wrong number of copies owned");
    assertTrue(canMintAi, "Should be able to mint AI variants");

    // Check userEditionCount
    uint256 editionCount = engine.userEditionCount(buyer, tokenId);
    assertEq(editionCount, purchaseQuantity, "Wrong edition count");

    // Verify buyer is in buyers list
    address[] memory buyersList = engine.getBuyers();
    assertEq(buyersList[0], buyer, "Buyer not added to buyers list");

    // Check items sold counter
    assertEq(engine.getItemsSold(), 1, "Items sold counter not incremented");

    // Check remaining editions
    uint256 remainingEditions = editionSize - purchaseQuantity;
    assertEq(remainingEditions, 15, "Wrong number of remaining editions");
  }

  // Additional negative tests
  // function testPurchaseMultipleEditionFailsWithInsufficientPayment() public {
  //   // Setup
  //   vm.deal(owner, 1 ether);
  //   vm.prank(owner);
  //   engine.mint("ipfs://example", "desc", "name", 0.08 ether, 20);

  //   // Try to purchase with insufficient payment
  //   vm.deal(buyer, 1 ether);
  //   vm.prank(buyer);
  //   vm.expectRevert(PhotoFactoryEngine__InvalidAmount.selector);
  //   engine.purchase{value: 0.07 ether}(1, 1);
  // }

  // function testPurchaseMultipleEditionFailsWithExcessiveQuantity() public {
  //   // Setup
  //   vm.deal(owner, 1 ether);
  //   vm.prank(owner);
  //   engine.mint("ipfs://example", "desc", "name", 0.08 ether, 20);

  //   // Try to purchase more than available
  //   vm.deal(buyer, 10 ether);
  //   vm.prank(buyer);
  //   vm.expectRevert(PhotoFactoryEngine__InvalidAmount.selector);
  //   engine.purchase{value: 2 ether}(1, 25);
  // }
}
