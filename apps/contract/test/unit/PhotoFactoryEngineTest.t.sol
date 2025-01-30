// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {DeployPhotoFactory} from "../../script/DeployPhotoFactory.s.sol";
import {PhotoFactory721} from "../../src/PhotoFactory721.sol";
import {PhotoFactory1155} from "../../src/PhotoFactory1155.sol";
import {PhotoFactoryEngine} from "../../src/PhotoFactoryEngine.sol";
import {IPhotoFactoryEngine} from "../../src/interfaces/IPhotoFactoryEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

// TODO: Test usdc payment.
contract PhotoFactoryEngineTest is Test {
  DeployPhotoFactory deployer;
  PhotoFactoryEngine engine;
  PhotoFactory721 factory721;
  PhotoFactory1155 factory1155;
  HelperConfig helperConfig;

  address owner;
  address buyer;
  address secondBuyer;

  // Test variables
  string constant TOKEN_URI = "ipfs://example";
  string constant DESCRIPTION = "A shot in the wild";
  string constant PHOTO_NAME = "Lion smile";
  uint96 constant PRICE = 0.08 ether;
  uint32 constant EDITION_SIZE = 1;

  function setUp() public {
    owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Use a specific address for the owner
    buyer = makeAddr("buyer");
    secondBuyer = makeAddr("secondBuyer");

    deployer = new DeployPhotoFactory();
    (engine, factory721, factory1155, helperConfig) = deployer.run();
  }

  /*Test Deployment*/
  function testDeployment() public view {
    assert(address(engine) != address(0));
    assert(address(factory721) != address(0));
    assert(address(factory1155) != address(0));
  }

  // /*Test single edition mint*/
  function testMintSingleEdition() public {
    vm.deal(owner, 1 ether);
    vm.prank(owner);
    uint256 tokenId = engine.createPhoto(
      PHOTO_NAME,
      DESCRIPTION,
      TOKEN_URI,
      EDITION_SIZE,
      PRICE
    );

    // Get the photo details after minting to verify mint
    IPhotoFactoryEngine.PhotoView memory photoItem = engine.getPhotoItem(
      tokenId
    );

    assertEq(photoItem.tokenId, tokenId);
    assertEq(photoItem.collectionId, 0);

    assertEq(photoItem.name, PHOTO_NAME);
    assertEq(photoItem.editionSize, EDITION_SIZE);
    assertEq(photoItem.price, PRICE);
    assertEq(photoItem.creator, owner);
  }

  /* Purchase Tests */
  function testPurchaseSingleEdition() public {
    // Mint
    vm.prank(owner);
    uint256 tokenId = engine.createPhoto(
      PHOTO_NAME,
      DESCRIPTION,
      TOKEN_URI,
      EDITION_SIZE,
      PRICE
    );

    // Purchase
    vm.deal(buyer, 1 ether);
    vm.prank(buyer);
    engine.purchase{value: PRICE}(tokenId, 1, false);

    // Verify purchase
    IPhotoFactoryEngine.PhotoView memory photo = engine.getPhotoItem(tokenId);
    assertEq(photo.totalEditionsSold, 1);
    assertTrue(photo.ownersList[0] == buyer);
  }

  function testFailPurchaseWithInsufficientPayment() public {
    vm.prank(owner);
    uint256 tokenId = engine.createPhoto(
      PHOTO_NAME,
      DESCRIPTION,
      TOKEN_URI,
      EDITION_SIZE,
      PRICE
    );

    vm.deal(buyer, 1 ether);
    vm.prank(buyer);
    engine.purchase{value: PRICE - 0.01 ether}(tokenId, 1, false);
  }

  function testCollectionMint() public {
    string memory collectionName = "Spain trip";
    string memory collectionDescription = "Photos from my trip to Spain";
    IPhotoFactoryEngine.PhotoCreationParams[]
      memory photo = new IPhotoFactoryEngine.PhotoCreationParams[](2);
    IPhotoFactoryEngine.CollectionCategory[]
      memory categories = new IPhotoFactoryEngine.CollectionCategory[](2);
    string[] memory collectionTags = new string[](2);

    photo[0] = IPhotoFactoryEngine.PhotoCreationParams({
      name: "Spain beach",
      description: "A beautiful beach in Spain",
      tokenURI: "ipfs://example",
      editionSize: 1,
      price: 0.08 ether
    });

    photo[1] = IPhotoFactoryEngine.PhotoCreationParams({
      name: "Spain sunset",
      description: "A beautiful sunset in Spain",
      tokenURI: "ipfs://example2",
      editionSize: 5,
      price: 0.08 ether
    });

    categories[0] = IPhotoFactoryEngine.CollectionCategory.Nature;
    categories[1] = IPhotoFactoryEngine.CollectionCategory.Travel;

    collectionTags[0] = "Spain";
    collectionTags[1] = "Travel";

    IPhotoFactoryEngine.CollectionCreationParams
      memory collection = IPhotoFactoryEngine.CollectionCreationParams({
        name: collectionName,
        description: collectionDescription,
        categories: categories,
        photoCreationParams: photo,
        tags: collectionTags,
        coverImageURI: "ipfs://cover",
        featuredPhotoURI: "ipfs://featured"
      });

    vm.deal(owner, 1 ether);
    vm.prank(owner);

    engine.createCollection(collection);

    // Get the collection details
    IPhotoFactoryEngine.Collection memory collectionItem = engine.getCollection(
      1
    );

    // Check the cgllection details
    assertEq(collectionItem.collectionId, 1);
    assertEq(collectionItem.name, collectionName);
    assertEq(collectionItem.photoIds.length, 2);
  }

  function testPurchaseMultipleEdition() public {
    // Mint multiple edition
    uint32 multipleEditionSize = 5;
    vm.prank(owner);
    uint256 tokenId = engine.createPhoto(
      PHOTO_NAME,
      DESCRIPTION,
      TOKEN_URI,
      multipleEditionSize,
      PRICE
    );

    // First purchase
    vm.deal(buyer, 1 ether);
    vm.prank(buyer);
    engine.purchase{value: PRICE * 2}(tokenId, 2, false);

    // Second purchase
    vm.deal(secondBuyer, 1 ether);
    vm.prank(secondBuyer);
    engine.purchase{value: PRICE * 2}(tokenId, 2, false);

    // Verify purchases
    IPhotoFactoryEngine.PhotoView memory photo = engine.getPhotoItem(tokenId);
    assertEq(photo.totalEditionsSold, 4);
    assertTrue(photo.ownersList.length == 2);
  }

  /* Price Update Tests */
  function testUpdatePrice() public {
    vm.startPrank(owner);
    uint256 tokenId = engine.createPhoto(
      PHOTO_NAME,
      DESCRIPTION,
      TOKEN_URI,
      EDITION_SIZE,
      PRICE
    );

    uint96 newPrice = 0.1 ether;
    engine.updatePrice(tokenId, newPrice);
    vm.stopPrank();

    uint256 updatedPrice = engine.getPrice(tokenId);
    assertEq(updatedPrice, newPrice);
  }

  function testFailUpdatePriceNonOwner() public {
    vm.prank(owner);
    uint256 tokenId = engine.createPhoto(
      PHOTO_NAME,
      DESCRIPTION,
      TOKEN_URI,
      EDITION_SIZE,
      PRICE
    );

    vm.prank(buyer);
    engine.updatePrice(tokenId, 0.1 ether);
  }

  /* Events Tests */
  function testEmitPhotoCreatedEvent() public {
    vm.prank(owner);
    vm.expectEmit(true, true, false, true);
    emit IPhotoFactoryEngine.PhotoCreated(
      1,
      IPhotoFactoryEngine.EditionType.Single,
      EDITION_SIZE,
      0
    );
    engine.createPhoto(PHOTO_NAME, DESCRIPTION, TOKEN_URI, EDITION_SIZE, PRICE);
  }

  function testEmitPhotoPurchasedEvent() public {
    vm.prank(owner);
    uint256 tokenId = engine.createPhoto(
      PHOTO_NAME,
      DESCRIPTION,
      TOKEN_URI,
      EDITION_SIZE,
      PRICE
    );

    vm.deal(buyer, 1 ether);
    vm.prank(buyer);

    vm.expectEmit(true, true, false, true);
    emit IPhotoFactoryEngine.PhotoPurchased(tokenId, buyer, 1, PRICE);
    engine.purchase{value: PRICE}(tokenId, 1, false);
  }
}
