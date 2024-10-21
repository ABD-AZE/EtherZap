//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "lib/forge-std/src/Script.sol";
import "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../src/ZapAccountFactory.sol";
contract MyZapAccountFactory is Script{ 
    IEntryPoint private i_entrypoint;
    function run() external {
        i_entrypoint = IEntryPoint(address(0x0000000071727De22E5E9d8BAf0edAc6f37da032));
        vm.startBroadcast();
        ZapAccountFactory factory = new ZapAccountFactory(i_entrypoint);
        vm.stopBroadcast();
    }
}