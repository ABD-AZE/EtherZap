//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "../lib/forge-std/src/Script.sol";
import "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import "../src/ZapAccountFactory.sol";
contract MyZapAccountFactory is Script{ 
    EntryPoint private immutable i_entrypoint;
    constructor(EntryPoint entrypoint) {
        i_entrypoint=entrypoint;
    }
    function run() external {
        vm.startBroadcast();
        ZapAccountFactory factory = new ZapAccountFactory(i_entrypoint);
        vm.stopBroadcast();
    }
}