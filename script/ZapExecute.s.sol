// SPDX-License-Identifier: MIT

//2678df87e92d502ebe0686d9cba733867d6b4a76cadfae9fb12eeb9fa931b505


pragma solidity ^0.8.9;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {EntryPoint,PackedUserOperation} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract Deploy is Script {
    // address AF = 0x8464135c8F25Da09e49BC8782676a84730C318bC;
     //address EP = 0x71C95911E9a5D330f4D621842EC243EE1343292e;
    address AF = 0xD76EF76C40F2888d0D22F6d6551500c063Fd4153;
   address EP=   0xEdf47C7E665bEb76b216205573935236f89ae83A;
    //address EP= 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    // struct PackedUserOperation {
    //     address sender;
    //     uint256 nonce;
    //     bytes initCode;
    //     bytes callData;
    //     bytes32 accountGasLimits;
    //     uint256 preVerificationGas;
    //     bytes32 gasFees;
    //     bytes paymasterAndData;
    //     bytes signature;
    // }

    EntryPoint ep = EntryPoint(payable(EP));

    function run() external {
        
         uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        address sender = vm.computeCreateAddress(AF, 1);
        bytes memory ic = hex"D76EF76C40F2888d0D22F6d6551500c063Fd41539859387b000000000000000000000000372610bdcfa0531b40c8b27bb22a4e198ef04604";

        PackedUserOperation memory userOp=PackedUserOperation({
            sender: sender,
            nonce: ep.getNonce(sender,0),
            initCode: ic,
            callData: hex"61461954",
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit), // Increased gas limit
            preVerificationGas: verificationGasLimit, // Increased pre-verification gas
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas), // Increased gas price
            paymasterAndData: hex"",
            signature: hex""
        });
        bytes32 userOpHash= ep.getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
         uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 SEPOLIA_DEFAULT_KEY= 0x2678df87e92d502ebe0686d9cba733867d6b4a76cadfae9fb12eeb9fa931b505;
        uint256 ANVIL_DEFAULT_KEY=  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        (v, r, s) = vm.sign(SEPOLIA_DEFAULT_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        userOp.signature= sig;
        

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
           vm.startBroadcast();
           ep.depositTo{value:0.1 ether}(sender);
        uint256 gasLimit = 10_000_000_000; // Adjust this value as needed
        ep.handleOps{gas: gasLimit}(ops, payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));

           

        vm.stopBroadcast();
    }
}