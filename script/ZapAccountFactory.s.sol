//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "lib/forge-std/src/Script.sol";
import "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../src/ZapAccountFactory.sol";
contract MyZapAccountFactory is Script{ 
    IEntryPoint private i_entrypoint;
    function run() external {
        i_entrypoint = IEntryPoint(address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789));
        vm.startBroadcast();
        ZapAccountFactory factory = new ZapAccountFactory(i_entrypoint);
        vm.stopBroadcast();
    }
}