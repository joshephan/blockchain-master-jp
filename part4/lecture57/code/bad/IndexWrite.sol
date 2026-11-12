// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract IndexWrite {
    function f() external pure returns (bytes32) {
        bytes32 b = keccak256("alice");
        b[0] = 0x01;
        return b;
    }
}
