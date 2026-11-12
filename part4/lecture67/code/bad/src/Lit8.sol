// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lit8 {
    function f() public pure returns (int256) {
        int256[3] memory a = [int256(1), 2, -3];
        return a[2];
    }
}
