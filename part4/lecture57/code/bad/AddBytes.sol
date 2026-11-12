// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract AddBytes {
    function f(bytes4 a, bytes4 b) external pure returns (bytes4) {
        return a + b;
    }
}
