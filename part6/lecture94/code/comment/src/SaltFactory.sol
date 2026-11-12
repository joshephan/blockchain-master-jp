// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Child} from "./Child.sol";

contract SaltFactory {
    function makeSalted(bytes32 salt, uint256 x) external returns (Child) {
        return new Child{salt: salt}(x);
    }

    // CREATE2アドレスを直接計算
    function predict(bytes32 salt, bytes memory initCode) public view returns (address) {
        bytes32 h = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(initCode)));
        return address(uint160(uint256(h)));
    }

    function predictChild(bytes32 salt, uint256 x) external view returns (address) {
        return predict(salt, abi.encodePacked(type(Child).creationCode, abi.encode(x)));
    }
}
