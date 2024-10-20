pragma solidity ^0.8.9;

import {Script} from "../lib/forge-std/src/Script.sol";
import {ZapPayMaster} from "../src/ZapPaymasterTemp.sol";

contract DeployPaymaster is Script{
    address public EP = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    function run() external {
        vm.startBroadcast();
        ZapPayMaster zpm = new ZapPayMaster(EP);
        vm.stopBroadcast();
    }
}