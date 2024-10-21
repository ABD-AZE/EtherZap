// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UserManager.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract DeployUserManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address serverManager = vm.envAddress("SERVER_MANAGER_ADDRESS");
        
        // For testnet deployment, use these values
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        
        if (block.chainid == 11155111) { // Sepolia
            vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
            keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
            subscriptionId = uint64(vm.envUint("SUBSCRIPTION_ID"));
        } else { // Local testing
            vm.startBroadcast(deployerPrivateKey);
            VRFCoordinatorV2Mock vrfMock = new VRFCoordinatorV2Mock(
                0.1 ether,
                1e9
            );
            subscriptionId = vrfMock.createSubscription();
            vrfMock.fundSubscription(subscriptionId, 2 ether);
            vrfCoordinator = address(vrfMock);
            keyHash = keccak256("TEST_HASH");
            vm.stopBroadcast();
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        UserManager userManager = new UserManager(
            serverManager,
            vrfCoordinator,
            keyHash,
            subscriptionId
        );
        
        console.log("UserManager deployed to:", address(userManager));
        
        vm.stopBroadcast();
    }
}