// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {UserManager} from "../src/UserManager.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract UserManagerTest is Test {
    UserManager public userManager;
    VRFCoordinatorV2Mock public vrfCoordinator;
    
    address public constant SERVER_MANAGER = address(1);
    address public constant USER = address(2);
    address public constant SPONSOR = address(3);
    
    uint64 public constant SUBSCRIPTION_ID = 1;
    bytes32 public constant KEY_HASH = bytes32("key_hash");
    uint96 public constant FUND_AMOUNT = 1 ether;
    
    event AdCreated(uint256 indexed adId, address indexed sponsor, UserManager.AdType adType, string contentId, uint256 quantity, uint256 price);
    event RandomAdRequested(uint256 requestId, UserManager.AdType adType);
    event RandomAdFulfilled(uint256 randomAdIndex, UserManager.AdType adType);

    function setUp() public {
        // Deploy VRF Coordinator mock
        vrfCoordinator = new VRFCoordinatorV2Mock(
            0.1 ether, // base fee
            1e9        // gas price link
        );
        
        // Create and fund subscription
        vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(SUBSCRIPTION_ID, FUND_AMOUNT);
        
        // Deploy UserManager
        userManager = new UserManager(
            SERVER_MANAGER,
            address(vrfCoordinator),
            KEY_HASH,
            SUBSCRIPTION_ID
        );
        
        // Add consumer to subscription
        vrfCoordinator.addConsumer(SUBSCRIPTION_ID, address(userManager));
    }

    function testSubmitAd() public {
        uint256 quantity = 5;
        string memory contentId = "test_content";
        uint256 expectedPrice = quantity * userManager.COST_PER_AD();
        
        vm.startPrank(SPONSOR);
        vm.deal(SPONSOR, 1 ether);
        
        vm.expectEmit(true, true, false, true);
        emit AdCreated(0, SPONSOR, UserManager.AdType.Video, contentId, quantity, expectedPrice);
        
        userManager.submitAd{value: expectedPrice}(
            UserManager.AdType.Video,
            quantity,
            contentId
        );
        
        UserManager.Ad memory ad = userManager.getAd(0);
        assertEq(ad.sponsor, SPONSOR);
        assertEq(ad.quantity, quantity);
        assertEq(ad.price, expectedPrice);
        assertEq(uint(ad.adType), uint(UserManager.AdType.Video));
        assertEq(ad.contentId, contentId);
        assertEq(uint(ad.status), uint(UserManager.AdStatus.Active));
        
        vm.stopPrank();
    }

    function testRequestRandomVideoAd() public {
        // First submit an ad
        vm.startPrank(SPONSOR);
        vm.deal(SPONSOR, 1 ether);
        userManager.submitAd{value: 0.05 ether}(
            UserManager.AdType.Video,
            5,
            "test_content"
        );
        vm.stopPrank();
        
        vm.prank(USER);
        uint256 requestId = userManager.requestRandomVideoAd();
        
        // Verify request was made
        assertEq(userManager.requestIdToUser(requestId), USER);
        assertEq(uint(userManager.requestIdToAdType(requestId)), uint(UserManager.AdType.Video));
    }

    function testFulfillRandomWords() public {
        // Submit multiple ads
        vm.startPrank(SPONSOR);
        vm.deal(SPONSOR, 2 ether);
        
        userManager.submitAd{value: 0.05 ether}(
            UserManager.AdType.Video,
            5,
            "video_1"
        );
        
        userManager.submitAd{value: 0.05 ether}(
            UserManager.AdType.Video,
            5,
            "video_2"
        );
        vm.stopPrank();
        
        // Request random ad
        vm.prank(USER);
        uint256 requestId = userManager.requestRandomVideoAd();
        
        // Simulate VRF response
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456; // Random number
        
        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(userManager));
        
        // Verify random ad was selected
        assertTrue(userManager.randomVideoAdIndex() < userManager.getAdCount());
    }

    function testVideoAdVerification() public {
        uint256 videoId = 1;
        uint256 videoDuration = 30;
        
        // Get current nonce
        uint256 nonce = userManager.nonces(USER);
        
        // Start video ad
        vm.prank(SERVER_MANAGER);
        userManager.startVideoAd(videoId, nonce, videoDuration);
        
        // Fast forward time
        vm.warp(block.timestamp + videoDuration);
        
        // Generate signature for verification
        bytes32 message = keccak256(abi.encodePacked(USER, block.timestamp, videoId, nonce));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, message); // SERVER_MANAGER's private key
        bytes memory signature = abi.encodePacked(r, s, v);
        
        bool isValid = userManager.verifyAdWatch(
            USER,
            block.timestamp,
            videoId,
            nonce,
            signature
        );
        
        assertTrue(isValid);
    }

    function testViewBannerAd() public {
        // Submit banner ad
        vm.startPrank(SPONSOR);
        vm.deal(SPONSOR, 1 ether);
        uint256 quantity = 5;
        uint256 cost = quantity * userManager.COST_PER_AD();
        userManager.submitAd{value: cost}(
            UserManager.AdType.Banner,
            quantity,
            "banner_1"
        );
        vm.stopPrank();
        
        // Store initial banner ads viewed count
        (uint256 initialBannerAdsViewed, uint256 initialVideoAdsViewed) = (
            userManager.users(SERVER_MANAGER)
        );
        
        // Set status to Inactive to allow viewing
        vm.store(
            address(userManager),
            keccak256(abi.encode(0, uint256(keccak256("ads")))), // storage slot for first ad
            bytes32(uint256(1)) // Set status to Inactive (1)
        );
        
        // View banner ad
        vm.prank(SERVER_MANAGER);
        userManager.viewBannerAd(0);
        
        // Check that banner ads viewed count increased by 1
        (uint256 finalBannerAdsViewed, uint256 finalVideoAdsViewed) = (
            userManager.users(SERVER_MANAGER)
        );
        
        assertEq(finalBannerAdsViewed, initialBannerAdsViewed + 1);
        assertEq(finalVideoAdsViewed, initialVideoAdsViewed); // Video ads count should remain unchanged
    }

    function testFailSubmitAdInsufficientPayment() public {
        vm.startPrank(SPONSOR);
        vm.deal(SPONSOR, 0.001 ether);
        
        vm.expectRevert("Must pay the exact amount for the ad");
        userManager.submitAd{value: 0.001 ether}(
            UserManager.AdType.Video,
            5,
            "test_content"
        );
        
        vm.stopPrank();
    }

    function testFailNonServerFunctions() public {
        vm.startPrank(USER);
        
        vm.expectRevert("Only server can call this function");
        userManager.startVideoAd(1, 0, 30);
        
        vm.expectRevert("Only server can call this function");
        userManager.viewBannerAd(0);
        
        vm.stopPrank();
    }

    receive() external payable {}
}
