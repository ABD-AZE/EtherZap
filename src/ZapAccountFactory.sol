// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ZapAccount.sol";

contract ZapAccountFactory {
    IEntryPoint private immutable _entryPoint;

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
    }

    function createAccount(address owner, uint256 salt) public returns (address ) {
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return payable(addr);
        }
       ZapAccount ret = new ZapAccount{salt: bytes32(salt)}(owner);
        return address(ret);
    }

    function getAddress(address owner, uint256 salt) public view returns (address) {
        bytes32 byteSalt = bytes32(salt);
        bytes memory bytecode = abi.encodePacked(type(ZapAccount).creationCode, abi.encode(owner));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), byteSalt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
}
