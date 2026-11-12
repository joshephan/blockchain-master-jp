// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BadWrite {
    function f(bytes calldata data) external pure {
        bytes calldata rest = data[4:];
        rest[0] = 0x01;
    }
}
