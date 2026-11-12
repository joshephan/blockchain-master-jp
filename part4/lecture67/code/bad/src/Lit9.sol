// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lit9 {
    function f() public pure returns (int8) {
        int8[2] memory c = [-1, 1];
        return c[1];
    }
}
