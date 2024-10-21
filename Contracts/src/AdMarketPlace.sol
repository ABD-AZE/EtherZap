// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdMarketPlace{
    enum AdType{Video,Banner}
    struct Ad{
        uint256 id;
        address sponsor;
        AdType adType;
        string contentId;
        uint256 quantity;
        uint256 price;
        


    }
    mapping(uint256=>Ad) public ads;
    uint256 public adCount;
    uint256 public constant COST_PER_AD = 0.01 ether;
    event AdCreated(uint256 indexed adId,address indexed sponsor,AdType adType,string contentId,uint256 quantity,uint256 price);
    function submitAd(AdType adType,uint256 quantity,string memory contentId)public payable{
        require(quantity>0,"Quantity must be greater than zero");
        uint256 totalPrice=quantity*COST_PER_AD;
        require(msg.value == totalPrice, "Must pay the exact amount for the ad");

        ads[adCount]=Ad({
            id: adCount,
            sponsor: msg.sender,
            adType: adType,
            contentId: contentId,
            quantity: quantity,
            price: totalPrice
        });
        emit AdCreated(adCount, msg.sender, adType, contentId, quantity, totalPrice);
        adCount++;
    }
}