// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "forge-std/Test.sol";
import "../src/AdMarketPlace.sol";

contract AdMarketPlaceTest is Test{
    AdMarketPlace public adMarket;
    function setUp() public {
        adMarket = new AdMarketPlace();
    }
    function testAdCreated() public{
        uint256 quantity=98;
        AdMarketPlace.AdType adType=AdMarketPlace.AdType.Video;
        string memory contentId="ipfs://///";
        uint256 totalCost=adMarket.COST_PER_AD()*quantity;
        adMarket.submitAd{value:totalCost}(adType,quantity,contentId);
        ( , address sponsor, AdMarketPlace.AdType storedAdType, string memory storedContentId, uint256 storedQuantity, uint256 price) = adMarket.ads(0);

        assertEq(sponsor, address(this)); // Check that the sponsor is the test contract (or msg.sender)
        assertEq(uint(storedAdType), uint(adType)); // Check that adType is stored correctly
        assertEq(storedContentId, contentId); // Check that the content ID matches
        assertEq(storedQuantity, quantity); // Check that quantity is stored correctly
        assertEq(price, totalCost); // Check that price is stored correctly

    }
    function testQuantityZero() public{
        uint256 quantity=0;
        AdMarketPlace.AdType adType=AdMarketPlace.AdType.Video;
        string memory contentId="ipfs://///";
        uint256 totalCost=adMarket.COST_PER_AD()*quantity;
        vm.expectRevert("Quantity must be greater than zero");
        adMarket.submitAd{value:totalCost}(adType,quantity,contentId);


    }
    function testLessPay() public{
        uint256 quantity=5;
        uint256 totalCost=adMarket.COST_PER_AD()*quantity-1;
        string memory contentId="ipfs";
        AdMarketPlace.AdType adType=AdMarketPlace.AdType.Banner;
        vm.expectRevert("Must pay the exact amount for the ad");
        adMarket.submitAd{value:totalCost}(adType,quantity,contentId);

    }
    function testMultipleAds() public {
        uint256 quantity1 = 1;
        AdMarketPlace.AdType adType1 = AdMarketPlace.AdType.Video;
        string memory contentId1 = "ipfs://ad1/";
        uint256 totalCost1 = adMarket.COST_PER_AD() * quantity1;
        adMarket.submitAd{value: totalCost1}(adType1, quantity1, contentId1);
        
  
        uint256 quantity2 = 1;
        AdMarketPlace.AdType adType2 = AdMarketPlace.AdType.Video;
        string memory contentId2 = "ipfs://ad2/";
        uint256 totalCost2 = adMarket.COST_PER_AD() * quantity2;
        adMarket.submitAd{value: totalCost2}(adType2, quantity2, contentId2);
    
    
    (uint256 id1, address sponsor1, AdMarketPlace.AdType storedAdType1, string memory storedContentId1, uint256 storedQuantity1, ) = adMarket.ads(0);
    assertEq(id1, 0); 
    assertEq(storedContentId1, contentId1); 

    // Check the second ad
    (uint256 id2, address sponsor2, AdMarketPlace.AdType storedAdType2, string memory storedContentId2, uint256 storedQuantity2, uint256 price2) = adMarket.ads(1);
    assertEq(id2, 1);
    assertEq(storedContentId2, contentId2);

    }
    function testEventEmission() public {
        uint256 quantity = 1;
        AdMarketPlace.AdType adType = AdMarketPlace.AdType.Video;
        string memory contentId = "ipfs://///";

        vm.expectEmit(true, true, true, true);
        emit AdMarketPlace.AdCreated(0, address(this), adType, contentId, quantity, adMarket.COST_PER_AD() * quantity);

        adMarket.submitAd{value: adMarket.COST_PER_AD() * quantity}(adType, quantity, contentId);
    }


}