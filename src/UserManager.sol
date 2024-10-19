// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {Nonces} from "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
contract UserManager is Nonces {

mapping(address => mapping(uint256 => uint256)) public userStartTimes; 
mapping(uint256 => uint256) public vidTimestamps;  // video id to timestamp
mapping(uint256=>Ad) public ads;
uint256 public adCount;
uint256 public constant COST_PER_AD = 0.01 ether;
uint256 public totalWeight;
   
address public immutable i_ServerManager;

 enum AdType{Video,Banner}
    enum AdStatus{Active,Inactive}
    struct Ad{
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


event AdCreated(uint256 indexed adId,address indexed sponsor,AdType adType,string contentId,uint256 quantity,uint256 price);


    constructor(address _serverManager) {
   
        i_ServerManager = _serverManager;
    }

    modifier OnlyServer() {
        require(msg.sender == i_ServerManager , "Only server can call this function");
        _;
    }

    function verifyAdWatch(address user ,  uint256 timestamp , uint256 videoId , uint256 _nonce , bytes memory signature) public view returns(bool) {
      require(nonces(user) == _nonce + 1 , "Invalid nonce");
      require(timestamp - userStartTimes[user][_nonce] >= vidTimestamps[videoId] , "Invalid timestamp");
        bytes32 message = keccak256(abi.encodePacked(user ,  timestamp , videoId , _nonce));
        address signer = ECDSA.recover(message , signature);
        return signer == i_ServerManager;
    }

    function startVideoAd(uint256 videoId , uint256 nonce , uint256 videoDuration) public OnlyServer {
        vidTimestamps[videoId] = videoDuration;
        userStartTimes[msg.sender][nonce] = block.timestamp;
        _useNonce(msg.sender);
    }

    function viewBannerAd(uint256 adId) public OnlyServer {
        require(_allowAdView(adId) , "Ad not available");
        users[msg.sender].bannerAdsViewed++;      
    }


    function verifyAdView(address user , uint256 adId , uint256 _nonce , bool clicked, bytes memory signature ) public view returns(bool , bool) {
      require(nonces(user) == _nonce + 1 , "Invalid nonce");
        bytes32 message = keccak256(abi.encodePacked(user ,  adId , _nonce , clicked));
        address signer = ECDSA.recover(message , signature);
        return (signer == i_ServerManager, clicked);
    }

    function submitAd(AdType adType,uint256 quantity,string memory contentId)public payable{
        require(quantity>0,"Quantity must be greater than zero");
        uint256 totalPrice=quantity*COST_PER_AD;
        require(msg.value >= totalPrice, "Must pay the exact amount for the ad");    
        ads[adCount]=Ad({
            id: adCount,
            sponsor: msg.sender,
            adType: adType,
            status: AdStatus.Active,
            contentId: contentId,
            quantity: quantity,
            price: totalPrice
        });
        totalWeight += quantity*totalPrice;
        emit AdCreated(adCount, msg.sender, adType, contentId, quantity, totalPrice);
        adCount++;
    }

    function _allowAdView(uint256 adId) internal returns (bool) {
        if (ads[adId].status == AdStatus.Active) {
            return false;
        }
        ads[adId].quantity--;
        if (ads[adId].quantity == 0) {
            ads[adId].status = AdStatus.Inactive;
        }     
        return true;
    }

    function getRandomAd() public view returns (Ad memory) {
        require(adCount > 0, "No ads available");

        uint256 randomWeight = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % totalWeight;

        uint256 adIndex = getAdIndex(randomWeight);

        return ads[adIndex];
    }
  
    function getAdIndex(uint256 randomWeight) internal view returns (uint256) {
        uint256 index = (randomWeight * adCount) / totalWeight;
        return index;
    }
    function getAd(uint256 adId) public view returns(Ad memory){
        return ads[adId];
    }
    function getAdCount() public view returns(uint256){
        return adCount;
    }

}
