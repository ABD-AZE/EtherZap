//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import "../lib/forge-std/src/Script.sol";
import "../src/ZapAccountFactory.sol";
contract Deploy is Script{
    function run() external {
        vm.startBroadcast();
        // address AF = 0x8464135c8F25Da09e49BC8782676a84730C318bC;
        //address EP = 0x71C95911E9a5D330f4D621842EC243EE1343292e;
        EntryPoint ep = new EntryPoint();
        ZapAccountFactory af = new ZapAccountFactory(ep);
        vm.stopBroadcast();
    }
}
