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
import "../src/ZapAccount.sol";
contract Deploy is Script {
    // change salt at 2 places
    //anvil
    // address AF = 0x90193C961A926261B756D1E5bb255e67ff9498A1;
    // address EP = 0x34A1D3fff3958843C43aD80F30b94c510645C316; 
    // base sepolia
    address public AF = 0x732DC53Ed45d08c716758bAcFCe660BE7641A35C;
    address public EP = 0x0000000071727De22E5E9d8BAf0edAc6f37da032 ;
    address public PM = 0x9af33f4a0e980272d98b65e655227c57d43f6c0c;
    //base sepolia
    uint256 salt  = 13579111512; 
    address myaddress = 0x509d5DC4d295a7F534eC58F0f75Fd723ab72F8D4;
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
        uint128 verificationGasLimit = 1000000; // Typical gas limit for a simple transaction
        uint128 callGasLimit = 100000; // Adjusted gas limit for contract execution
        uint128 maxPriorityFeePerGas = 619488; // 2 Gwei
        uint128 maxFeePerGas = 619488; // 50 Gwei
        address sender = getAddress(myaddress, salt); //vm.computeCreateAddress(AF, 1);
        console.log(sender);
        bytes memory Calldata =  generateCallData(address(0x9f13c3FA4eAE22A984c1f9c4936477C448540A22), 0, hex"");
        uint48 validUntil = uint48(block.timestamp + 1000);
        uint48 validAfter = uint48(block.timestamp);
        // bytes memory Calldata = generateCallData(address(0x9f13c3FA4eAE22A984c1f9c4936477C448540A22), 0.1 ether, hex"");
        bytes memory ic = generateInitCode(AF, myaddress, salt); 
        PackedUserOperation memory userOp= PackedUserOperation({
            sender: sender,
            nonce: ep.getNonce(sender,0),
            initCode: ic,
            callData: Calldata,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: uint256(1109448),
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
        bytes memory PMData = GeneratePaymasterAndData(userOp,validUntil , validAfter);
        userOp.paymasterAndData = PMData;
        // paymaster data:  first 20bytes are paymaster address, next 32 bytes 
        bytes32 userOpHash = ep.getUserOpHash(userOp);
        // bytes32 userOpHash = hex"";
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 BASE_SEPOLIA_DEFAULT_KEY = 0x9442ed40cedff46250c0d84d2f0ae177c08ffb4dfe8cf78a1f5b6e999aa18d44;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        // (v, r, s) = vm.sign(BASE_SEPOLIA_DEFAULT_KEY, digest);
        (v,r,s)  = vm.sign(BASE_SEPOLIA_DEFAULT_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        userOp.signature = sig;
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
        uint256 gasLimit = 2000000; // Adjust this value as needed
        vm.startBroadcast();
        // (bool success, ) = address(sender).call{value: 0.5 ether}("");
        ep.depositTo{value: 0.1 ether}(PM);
        // require(success, "Transfer failed");
        ep.handleOps{gas:gasLimit}(
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
            abi.encodeWithSelector(ZapAccount.execute.selector, dest,value,data);
    }
    function GeneratePaymasterAndData(PackedUserOperation memory userOp, uint48 validUntil, uint48 validAfter) public view returns (bytes memory) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(getHash(userOp, validUntil, validAfter));
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 BASE_SEPOLIA_DEFAULT_KEY = 0x9442ed40cedff46250c0d84d2f0ae177c08ffb4dfe8cf78a1f5b6e999aa18d44;
        (v,r,s) = vm.sign(BASE_SEPOLIA_DEFAULT_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes memory paymasterAndData = abi.encodePacked(
            address(PM),
            abi.encode(validUntil, validAfter),
            sig
        );
    }
    function getHash(PackedUserOperation calldata userOp, uint48 validUntil, uint48 validAfter)
    public view returns (bytes32) {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.
        address sender = userOp.getSender();
        return
            keccak256(
            abi.encode(
                sender,
                userOp.nonce,
                keccak256(userOp.initCode),
                keccak256(userOp.callData),
                userOp.accountGasLimits,
                uint256(bytes32(userOp.paymasterAndData[20 : 52])),
                userOp.preVerificationGas,
                userOp.gasFees,
                block.chainid,
                address(this),
                validUntil,
                validAfter
            )
        );
    }
}