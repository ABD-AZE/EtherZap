// SPDX-License-Identifier: MIT

//2678df87e92d502ebe0686d9cba733867d6b4a76cadfae9fb12eeb9fa931b505

pragma solidity ^0.8.9;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import {StdUtils} from "../lib/forge-std/src/StdUtils.sol";
import {EntryPoint, PackedUserOperation} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../src/ZapAccount.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract Deploy is Script {
    //anvil
    // address AF = 0x90193C961A926261B756D1E5bb255e67ff9498A1;
    // address EP = 0x34A1D3fff3958843C43aD80F30b94c510645C316; 
    // base sepolia
    address public AF = 0xe7849B3D7B2611B7FffED973645D9023567EFDBE;
    address public EP = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    uint256 private salt = 12098236182395721243;
    //base sepolia
    address myaddress = 0x9f13c3FA4eAE22A984c1f9c4936477C448540A22;
    //anvil
    // address myaddress  = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
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
        address sender = getAddress(myaddress, salt); //vm.computeCreateAddress(AF, 1);
        console.log(sender);
        console.log(salt);
        // bytes memory Calldata =  abi.encodeWithSignature("execute(address,uint256,bytes)",address(0x9f13c3FA4eAE22A984c1f9c4936477C448540A22) ,0.1 ether,hex"");
        // bytes memory Calldata = generateCallData(address(0x9f13c3FA4eAE22A984c1f9c4936477C448540A22), 0.1 ether, hex"");
        bytes memory ic = generateInitCode(AF, myaddress, salt);
        PackedUserOperation memory userOp= PackedUserOperation({
            sender: sender,
            nonce: ep.getNonce(sender,0),
            initCode: ic,
            callData: hex"",
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: uint256(verificationGasLimit),
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
        bytes32 userOpHash = ep.getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 BASE_SEPOLIA_DEFAULT_KEY = 0x1a8bb08a647acabdcdeea7f95123acf6ad5be964b0875784bc756609621b2973;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        // (v, r, s) = vm.sign(BASE_SEPOLIA_DEFAULT_KEY, digest);
        (v,r,s)  = vm.sign(BASE_SEPOLIA_DEFAULT_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        userOp.signature = sig;
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
        uint256 gasLimit = 10_000_000_000; // Adjust this value as needed
        vm.startBroadcast();
        // (bool success, ) = address(sender).call{value: 0.05 ether}("");
        // require(success, "Transfer failed");
        ep.depositTo{value: 0.05 ether}(sender);
        ep.handleOps{gas: gasLimit}(
            ops,
            payable(myaddress)
        );
        vm.stopBroadcast();
    }
    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        bytes32 byteSalt = bytes32(salt);
        bytes memory bytecode = abi.encodePacked(
            type(ZapAccount).creationCode,
            abi.encode(owner)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                AF,
                byteSalt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function generateInitCode(
        address factory,
        address owner,
        uint256 salt
    ) public pure returns (bytes memory) {
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "createAccount(address,uint256)",
            owner,
            salt
        );
        bytes memory initCode = abi.encodePacked(factory, encodedFunctionCall);
        return initCode;
    }
    function generateCallData(
        address dest,
        uint256 value,
        bytes memory data
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature("execute(address,uint256,bytes)", dest,value,data);
    }
}