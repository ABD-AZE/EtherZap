// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Nonces} from "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "../lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract UserManager is Nonces, VRFConsumerBaseV2 {
    mapping(address => mapping(uint256 => uint256)) public userStartTimes; 
    mapping(uint256 => uint256) public vidTimestamps;  // video id to timestamp
    mapping(uint256 => Ad) public ads;
    uint256 public adCount;
    uint256 public constant COST_PER_AD = 0.01 ether;
    uint256 public totalWeight;

    address public immutable i_ServerManager;

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // Request ID to store random result
    mapping(uint256 => address) public requestIdToUser;
    mapping(uint256 => AdType) public requestIdToAdType;
    uint256 public randomVideoAdIndex;
    uint256 public randomBannerAdIndex;

    event AdCreated(uint256 indexed adId, address indexed sponsor, AdType adType, string contentId, uint256 quantity, uint256 price);
    event RandomAdRequested(uint256 requestId, AdType adType);
    event RandomAdFulfilled(uint256 randomAdIndex, AdType adType);
    
    enum AdType { Video, Banner }
    enum AdStatus { Active, Inactive }
    
    struct Ad {
        uint256 id;
        address sponsor;
        AdType adType;
        AdStatus status;
        string contentId;
        uint256 quantity;
        uint256 price;
    }

    struct User {
        uint256 bannerAdsViewed;
        uint256 videoAdsViewed;
    }

    mapping(address => User) public users;

    constructor(
        address _serverManager,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_ServerManager = _serverManager;
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
    }

    modifier OnlyServer() {
        require(msg.sender == i_ServerManager, "Only server can call this function");
        _;
    }

    // Request randomness for video ads
    function requestRandomVideoAd() public returns (uint256 requestId) {
        require(adCount > 0, "No ads available");
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToUser[requestId] = msg.sender;
        requestIdToAdType[requestId] = AdType.Video; // Mark as video ad request
        emit RandomAdRequested(requestId, AdType.Video);
    }

    // Request randomness for banner ads
    function requestRandomBannerAd() public returns (uint256 requestId) {
        require(adCount > 0, "No ads available");
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToUser[requestId] = msg.sender;
        requestIdToAdType[requestId] = AdType.Banner; // Mark as banner ad request
        emit RandomAdRequested(requestId, AdType.Banner);
    }

    // Fulfillment function for Chainlink VRF
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        AdType adType = requestIdToAdType[requestId];
        uint256 randomWeight = randomWords[0] % totalWeight;

        if (adType == AdType.Video) {
            randomVideoAdIndex = getAdIndex(randomWeight, AdType.Video);
            emit RandomAdFulfilled(randomVideoAdIndex, AdType.Video);
        } else if (adType == AdType.Banner) {
            randomBannerAdIndex = getAdIndex(randomWeight, AdType.Banner);
            emit RandomAdFulfilled(randomBannerAdIndex, AdType.Banner);
        }
    }

    function getAdIndex(uint256 randomWeight, AdType adType) internal view returns (uint256) {
        uint256 index;
        uint256 weightSum = 0;

        for (uint256 i = 0; i < adCount; i++) {
            if (ads[i].adType == adType) {
                weightSum += ads[i].price; // Assuming price is used as weight for selection
                if (randomWeight < weightSum) {
                    index = i;
                    break;
                }
            }
        }

        return index;
    }

    function getAd(uint256 adId) public view returns (Ad memory) {
        return ads[adId];
    }

    function getAdCount() public view returns (uint256) {
        return adCount;
    }

    // Function to verify ad view, video ad start, and other logic
    function verifyAdWatch(address user, uint256 timestamp, uint256 videoId, uint256 _nonce, bytes memory signature) public view returns (bool) {
        require(nonces(user) == _nonce + 1, "Invalid nonce");
        require(timestamp - userStartTimes[user][_nonce] >= vidTimestamps[videoId], "Invalid timestamp");
        bytes32 message = keccak256(abi.encodePacked(user, timestamp, videoId, _nonce));
        address signer = ECDSA.recover(message, signature);
        return signer == i_ServerManager;
    }

    function startVideoAd(uint256 videoId, uint256 nonce, uint256 videoDuration) public OnlyServer {
        vidTimestamps[videoId] = videoDuration;
        userStartTimes[msg.sender][nonce] = block.timestamp;
        _useNonce(msg.sender); // Increment the nonce
    }

    function viewBannerAd(uint256 adId) public OnlyServer {
        require(_allowAdView(adId), "Ad not available");
        users[msg.sender].bannerAdsViewed++;      
    }

    function verifyAdView(address user, uint256 adId, uint256 _nonce, bool clicked, bytes memory signature) public view returns (bool, bool) {
        require(nonces(user) == _nonce + 1, "Invalid nonce");
        bytes32 message = keccak256(abi.encodePacked(user, adId, _nonce, clicked));
        address signer = ECDSA.recover(message, signature);
        return (signer == i_ServerManager, clicked);
    }

    function submitAd(AdType adType, uint256 quantity, string memory contentId) public payable {
        require(quantity > 0, "Quantity must be greater than zero");
        uint256 totalPrice = quantity * COST_PER_AD;
        require(msg.value >= totalPrice, "Must pay the exact amount for the ad");    
        
        ads[adCount] = Ad({
            id: adCount,
            sponsor: msg.sender,
            adType: adType,
            status: AdStatus.Active,
            contentId: contentId,
            quantity: quantity,
            price: totalPrice
        });

        totalWeight += quantity * totalPrice;
        emit AdCreated(adCount, msg.sender, adType, contentId, quantity, totalPrice);
        adCount++;
    }

    function _allowAdView(uint256 adId) internal returns (bool) {
        require(ads[adId].status == AdStatus.Active, "Ad not available");
        ads[adId].quantity--;
        if (ads[adId].quantity == 0) {
            ads[adId].status = AdStatus.Inactive;
        }     
        return true;
    }
}
