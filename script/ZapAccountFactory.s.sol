//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "lib/forge-std/src/Script.sol";
import "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../src/ZapAccountFactory.sol";
contract MyZapAccountFactory is Script{ 
    IEntryPoint private i_entrypoint;
    function run() external {
        i_entrypoint = IEntryPoint(0x0576a174D229E3cFA37253523E645A78A0C91B57);
        vm.startBroadcast();
        ZapAccountFactory factory = new ZapAccountFactory(_entryPoint);
        vm.stopBroadcast();
    }
}