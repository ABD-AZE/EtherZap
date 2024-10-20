// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "../src/AdMarketPlace.sol";
contract DeployAdMarket is Script{
    function run() external {
        vm.startBroadcast();
        new AdMarketPlace();
        vm.stopBroadcast();
    }
}