//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "../lib/forge-std/src/Script.sol";
import "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import "../src/ZapAccountFactory.sol";
contract MyZapAccountFactory is Script{ 
    IEntryPoint private immutable _entryPoint= IEntryPoint(0xEdf47C7E665bEb76b216205573935236f89ae83A);
    function run() external {
        vm.startBroadcast();
        ZapAccountFactory factory = new ZapAccountFactory(_entryPoint);
        vm.stopBroadcast();
    }
}