pragma solidity ^0.8.0;
    
contract InitCodeGenerator {
    function generateInitCode(address factory, address owner, uint256 salt) public pure returns (bytes memory) {
        bytes memory encodedFunctionCall = abi.encodeWithSignature("createAccount(address,uint256)", owner, salt);
        bytes memory initCode = abi.encodePacked(factory, encodedFunctionCall);
        return initCode;
    }
}