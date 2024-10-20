// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

import {Nonces} from "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "../lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract UserManager is Nonces, VRFConsumerBaseV2 {
    mapping(address => mapping(uint256 => uint256)) public userStartTimes;
    mapping(uint256 => uint256) public vidTimestamps;
    mapping(uint256 => Ad) public ads;
    mapping(uint256 => AdWeight) public adWeights;
    uint256 public adCount;
    uint256 public constant COST_PER_AD = 0.001 ether;
    uint256 public constant WEIGHT_PRECISION = 1000;

    // Weight configuration (total = 100)
    uint256 public priceWeight = 40;      // 40% importance
    uint256 public viewsWeight = 30;      // 30% importance
    uint256 public freshnessWeight = 20;  // 20% importance
    uint256 public performanceWeight = 10; // 10% importance

    address public immutable i_ServerManager;
    VRFCoordinatorV2Interface COORDINATOR;

//     uint64 s_subscriptionId;
//     // address vrfCoordinator;
//     bytes32 keyHash;
//     uint32 callbackGasLimit = 100000;
//     uint16 requestConfirmations = 3;
//     uint32 numWords = 1;

    mapping(uint256 => address) public requestIdToUser;
    mapping(uint256 => AdType) public requestIdToAdType;
    uint256 public randomVideoAdIndex;
    uint256 public randomBannerAdIndex;

    // Performance tracking
    mapping(uint256 => uint256) public adClicks;
    mapping(uint256 => uint256) public adViews;
    mapping(uint256 => uint256) public adLastServed; // Last block number when ad was served

    event AdCreated(uint256 indexed adId, address indexed sponsor, AdType adType, string contentId, uint256 quantity, uint256 price);
    event RandomAdRequested(uint256 requestId, AdType adType);
    event RandomAdFulfilled(uint256 randomAdIndex, AdType adType);
    event AdClicked(uint256 indexed adId, address indexed user);
    event WeightsUpdated(uint256 priceWeight, uint256 viewsWeight, uint256 freshnessWeight, uint256 performanceWeight);
    
//     enum AdType { Video, Banner }
//     enum AdStatus { Active, Inactive }
    
    struct Ad {
        uint256 id;
        address sponsor;
        AdType adType;
        AdStatus status;
        string contentId;
        uint256 quantity;
        uint256 price;
    }

    struct AdWeight {
        uint256 basePrice;      // Original price paid
        uint256 remainingViews; // Remaining ad views
        uint256 creationBlock;  // Block when ad was created
        uint256 performanceScore; // Click-through rate * 1000
    }

    struct User {
        uint256 bannerAdsViewed;
        uint256 videoAdsViewed;
        uint256 lastAdView;     // Last block number when user viewed an ad
    }

//     mapping(address => User) public users;

//     constructor(
//         address _serverManager,
//         address _vrfCoordinator,
//         bytes32 _keyHash,
//         uint64 _subscriptionId
//     ) VRFConsumerBaseV2(_vrfCoordinator) {
//         i_ServerManager = _serverManager;
//         vrfCoordinator = _vrfCoordinator;
//         COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
//         keyHash = _keyHash;
//         s_subscriptionId = _subscriptionId;
//     }

//     modifier OnlyServer() {
//         require(msg.sender == i_ServerManager, "Only server can call this function");
//         _;
//     }

    // Enhanced ad selection logic
    function calculateAdWeight(uint256 adId) public view returns (uint256) {
        AdWeight memory weight = adWeights[adId];
        Ad memory ad = ads[adId];
        
        if (ad.status != AdStatus.Active) {
            return 0;
        }

        // Price component (40%)
        uint256 priceComponent = (weight.basePrice * priceWeight * WEIGHT_PRECISION) / 
            (1 ether * 100);

        // Remaining views component (30%)
        uint256 viewsComponent = (weight.remainingViews * viewsWeight * WEIGHT_PRECISION) / 
            (ad.quantity * 100);

        // Freshness component (20%)
        uint256 blocksSinceCreation = block.number - weight.creationBlock;
        uint256 freshnessComponent = ((10000 - blocksSinceCreation) * freshnessWeight * WEIGHT_PRECISION) / 
            (10000 * 100);

        // Performance component (10%)
        uint256 performanceComponent = (weight.performanceScore * performanceWeight * WEIGHT_PRECISION) / 
            (1000 * 100);

        return priceComponent + viewsComponent + freshnessComponent + performanceComponent;
    }

    function getAdIndex(uint256 randomWeight, AdType adType) internal view returns (uint256) {
        uint256[] memory weights = new uint256[](adCount);
        uint256 totalWeights;
        
        // Calculate weights and total
        for (uint256 i = 0; i < adCount; i++) {
            if (ads[i].adType == adType && ads[i].status == AdStatus.Active) {
                weights[i] = calculateAdWeight(i);
                totalWeights += weights[i];
            }
        }
        
        require(totalWeights > 0, "No active ads available");
        
        // Select ad based on weighted random
        uint256 accumulatedWeight;
        uint256 targetWeight = (randomWeight % totalWeights);
        
        for (uint256 i = 0; i < adCount; i++) {
            if (ads[i].adType == adType && ads[i].status == AdStatus.Active) {
                accumulatedWeight += weights[i];
                if (accumulatedWeight > targetWeight) {
                    return i;
                }
            }
        }
        
        revert("Ad selection failed");
    }

    function requestRandomVideoAd() public returns (uint256 requestId) {
        require(adCount > 0, "No ads available");
        require(block.number >= users[msg.sender].lastAdView + 5, "Please wait before requesting new ad");
        
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        
        requestIdToUser[requestId] = msg.sender;
        requestIdToAdType[requestId] = AdType.Video;
        emit RandomAdRequested(requestId, AdType.Video);
    }

    function requestRandomBannerAd() public returns (uint256 requestId) {
        require(adCount > 0, "No ads available");
        require(block.number >= users[msg.sender].lastAdView + 3, "Please wait before requesting new ad");
        
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        
        requestIdToUser[requestId] = msg.sender;
        requestIdToAdType[requestId] = AdType.Banner;
        emit RandomAdRequested(requestId, AdType.Banner);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address user = requestIdToUser[requestId];
        AdType adType = requestIdToAdType[requestId];
        uint256 randomWeight = randomWords[0];

        if (adType == AdType.Video) {
            randomVideoAdIndex = getAdIndex(randomWeight, AdType.Video);
            users[user].lastAdView = block.number;
            emit RandomAdFulfilled(randomVideoAdIndex, AdType.Video);
        } else if (adType == AdType.Banner) {
            randomBannerAdIndex = getAdIndex(randomWeight, AdType.Banner);
            users[user].lastAdView = block.number;
            emit RandomAdFulfilled(randomBannerAdIndex, AdType.Banner);
        }
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

        adWeights[adCount] = AdWeight({
            basePrice: msg.value,
            remainingViews: quantity,
            creationBlock: block.number,
            performanceScore: 500 // Start with neutral 50% performance
        });

        emit AdCreated(adCount, msg.sender, adType, contentId, quantity, totalPrice);
        adCount++;
    }

    function trackAdClick(uint256 adId, address user) public OnlyServer {
        require(ads[adId].status == AdStatus.Active, "Ad not active");
        adClicks[adId]++;
        
        // Update performance score (CTR * 1000)
        if (adViews[adId] > 0) {
            adWeights[adId].performanceScore = (adClicks[adId] * 1000) / adViews[adId];
        }
        
        emit AdClicked(adId, user);
    }

    function _allowAdView(uint256 adId) internal returns (bool) {
        require(ads[adId].status == AdStatus.Active, "Ad not available");
        
        adWeights[adId].remainingViews--;
        adViews[adId]++;
        adLastServed[adId] = block.number;
        
        // Update performance score
        if (adViews[adId] > 0) {
            adWeights[adId].performanceScore = (adClicks[adId] * 1000) / adViews[adId];
        }
        
        if (adWeights[adId].remainingViews == 0) {
            ads[adId].status = AdStatus.Inactive;
        }
        
        return true;
    }

    // Existing functions remain unchanged
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
        _useNonce(msg.sender);
    }

//     function viewBannerAd(uint256 adId) public OnlyServer {
//         require(_allowAdView(adId), "Ad not available");
//         users[msg.sender].bannerAdsViewed++;      
//     }

//     function verifyAdView(address user, uint256 adId, uint256 _nonce, bool clicked, bytes memory signature) public view returns (bool, bool) {
//         require(nonces(user) == _nonce + 1, "Invalid nonce");
//         bytes32 message = keccak256(abi.encodePacked(user, adId, _nonce, clicked));
//         address signer = ECDSA.recover(message, signature);
//         return (signer == i_ServerManager, clicked);
//     }

    // Utility functions
    function getAd(uint256 adId) public view returns (Ad memory) {
        return ads[adId];
    }

    function getAdCount() public view returns (uint256) {
        return adCount;
    }

    function getAdWeight(uint256 adId) public view returns (AdWeight memory) {
        return adWeights[adId];
    }

    function getAdPerformance(uint256 adId) public view returns (uint256 clicks, uint256 views, uint256 score) {
        return (adClicks[adId], adViews[adId], adWeights[adId].performanceScore);
    }
}
