// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/account-abstraction/contracts/interfaces/IPaymaster.sol";
import "../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../lib/account-abstraction/contracts/core/Helpers.sol";
contract ZapPayMaster  {
    uint256 public constant PAYMASTER_DATA_OFFSET = 52;
    uint256 private constant VALID_TIMESTAMP_OFFSET = PAYMASTER_DATA_OFFSET;
    uint256 private constant SIGNATURE_OFFSET = VALID_TIMESTAMP_OFFSET + 64;
    uint256 public constant PAYMASTER_VALIDATION_GAS_OFFSET = 20;
    uint256 public constant PAYMASTER_POSTOP_GAS_OFFSET = 36;
    address public immutable i_entryPoint;
    address public immutable i_owner;

    constructor(address anEntryPoint) {
        i_entryPoint = anEntryPoint;
        i_owner = msg.sender;
    }

    modifier onlyEntryPoint() {
        require(msg.sender == i_entryPoint, "only entry point");
        _;
    }

    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    )
        external
        view
        onlyEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        return ("",0);
    }

    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (bytes memory context, uint256 validationData) {
        return ("", 1);
    }

    function getHash(
        PackedUserOperation calldata userOp,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes32) {
        address sender = userOp.sender;
        return
            keccak256(
                abi.encode(
                    sender,
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.accountGasLimits,
                    uint256(
                        bytes32(
                            userOp
                                .paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET:PAYMASTER_DATA_OFFSET]
                        )
                    ),
                    userOp.preVerificationGas,
                    userOp.gasFees,
                    block.chainid,
                    address(this),
                    validUntil,
                    validAfter
                )
            );
    }
    function parsePaymasterAndData(
        bytes calldata paymasterAndData
    )
        public
        pure
        returns (uint48 validUntil, uint48 validAfter, bytes calldata signature)
    {
        (validUntil, validAfter) = abi.decode(
            paymasterAndData[VALID_TIMESTAMP_OFFSET:],
            (uint48, uint48)
        );
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }

}
