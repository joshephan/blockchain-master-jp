// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lit5 {
    function f() public pure returns (uint256) {
        uint8[2] memory c = [1, 300];
        return c[1];
    }
}
