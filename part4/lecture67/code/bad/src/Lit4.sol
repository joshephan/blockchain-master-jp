// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lit4 {
    function f() public pure returns (int8) {
        int8[2] memory c = [int8(1), -1];
        return c[1];
    }
}
