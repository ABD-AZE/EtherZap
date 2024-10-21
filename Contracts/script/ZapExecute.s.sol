// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {Script} from "../lib/forge-std/src/Script.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import {StdUtils} from "../lib/forge-std/src/StdUtils.sol";
import {EntryPoint, PackedUserOperation} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../src/ZapAccount.sol";
import "../lib/forge-std/src/console.sol";
import "../src/ZapAccount.sol";
contract Deploy is Script {
    address public AF = 0xA3239e7354016c79fa873eB211EDA5Cf214Ca13b;
    address public EP = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    address public PM = 0xBC5ee9e1888037abF7B595bbD7031d50f586F657;
    uint256 salt = 13579;
    address myaddress = 0x6c2c4C594eE5093494e7a5D9D150bB9046486cdF;
    EntryPoint ep = EntryPoint(payable(EP));
    function run() external {
        uint128 verificationGasLimit = 1000000;
        uint128 callGasLimit = 10000000; 
        uint128 maxPriorityFeePerGas = 619488; 
        uint128 maxFeePerGas = 619488; 
        address sender = getAddress(myaddress, salt);

        // bytes memory Calldata = generateCallData(
        //     address(0x9f13c3FA4eAE22A984c1f9c4936477C448540A22),
        //     0,
        //     hex""
        // );
        uint48 validUntil = uint48(block.timestamp + 1000);
        uint48 validAfter = uint48(block.timestamp);
        bytes memory Calldata = generateCallData(address(0x523A8ad9A2f7636d0Bc47e63cA1a3E9474D05894), 0.0 ether, hex"725009d30000000000000000000000000000000000000000000000000000000000000000");
        bytes memory ic = generateInitCode(AF, myaddress, salt);
        bytes memory PMData = abi.encodePacked(PM,verificationGasLimit,verificationGasLimit); 
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: sender,
            nonce: ep.getNonce(sender, 0),
            initCode: hex"",
            callData: Calldata,
            accountGasLimits: bytes32(
                (uint256(verificationGasLimit) << 128) | callGasLimit
            ),
            preVerificationGas: uint256(verificationGasLimit),
            gasFees: bytes32(
                (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
            ),
            paymasterAndData: PMData,
            signature: hex""
        });
        // paymaster data:  first 20bytes are paymaster address
        bytes32 userOpHash = ep.getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 BASE_SEPOLIA_DEFAULT_KEY = 0xcea99f985118ba7f869d8778ba7f233d98ded0ea3899e27acc7b8709ded8030c;
        (v, r, s) = vm.sign(BASE_SEPOLIA_DEFAULT_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        userOp.signature = sig;
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    ops[0] = userOp;
        uint256 gasLimit = 20000000;
        vm.startBroadcast();
        ep.depositTo{value: 0.1 ether}(PM);
        ep.handleOps{gas: gasLimit}(ops, payable(0xbFFCa66179510D6C0CE3C2737b1942BF3f964519));
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
            abi.encodePacked(bytes1(0xff), AF, byteSalt, keccak256(bytecode))
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
            abi.encodeWithSelector(
                ZapAccount.execute.selector,
                dest,
                value,
                data
            );
    }
    function GenerateUnsignedPMData(
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes memory) {
        bytes memory paymasterAndData = abi.encodePacked(
            address(PM),
            abi.encode(validUntil, validAfter)
        );
        return paymasterAndData;
    }
    function GenerateSignedPMData(
        PackedUserOperation memory userOp,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes memory) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(
            getHash(userOp, validUntil, validAfter)
        );
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 BASE_SEPOLIA_DEFAULT_KEY = 0x9442ed40cedff46250c0d84d2f0ae177c08ffb4dfe8cf78a1f5b6e999aa18d44;
        (v, r, s) = vm.sign(BASE_SEPOLIA_DEFAULT_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes memory paymasterAndData = abi.encodePacked(
            address(PM),
            abi.encode(validUntil, validAfter),
            sig
        );
        return paymasterAndData;
    }
    function getHash(
        PackedUserOperation memory userOp,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes32) {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.
        uint256 extractedValue = uint256(
            extractBytes20(userOp.paymasterAndData, 20)
        );
        return
            keccak256(
                abi.encode(
                    userOp.sender,
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.accountGasLimits,
                    extractedValue,
                    userOp.preVerificationGas,
                    userOp.gasFees,
                    block.chainid,
                    PM,
                    validUntil,
                    validAfter
                )
            );
    }
    function extractBytes20(
        bytes memory data,
        uint256 start
    ) internal pure returns (bytes32 result) {
        require(data.length >= start + 32, "Insufficient data length");
        assembly {
            result := mload(add(data, add(0x20, start)))
        }
    }
}
