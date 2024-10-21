// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../lib/account-abstraction/contracts/interfaces/IAccountExecute.sol";
import "../lib/account-abstraction/contracts/interfaces/IAccount.sol";
import "../lib/account-abstraction/contracts/core/Helpers.sol";

contract ZapAccount is IAccount {
    address public immutable owner;
    IEntryPoint private immutable _entryPoint=IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);

    modifier onlyOwnerorEntryPoint() {
        require(msg.sender == owner || msg.sender == address(_entryPoint), "only owner or entry point");
        _;
    }

    constructor(address _owner) {
        owner=_owner;
    }

    function entryPoint() public view virtual returns (IEntryPoint) {
        return _entryPoint;
    }

    function execute(address dest, uint256 value, bytes calldata func) external onlyOwnerorEntryPoint {
        _call(dest, value, func);
    }

    function _call(address dest, uint256 value, bytes calldata func) internal {
        (bool success, bytes memory data) = dest.call{value: value}(func);
        require(success, string(data));
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        view
        returns (uint256 validationData)
    {
        return _validateUserOp(userOp, userOpHash);
    }

    function _validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        if (owner != ECDSA.recover(hash, userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }
}
