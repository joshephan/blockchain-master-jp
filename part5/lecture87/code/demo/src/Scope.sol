// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Scope {
    function f() external pure returns (uint256) {
        uint256 x = 1;        // x: ここから
        {
            uint256 y = 2;    // y: ここから
            x = x + y;
        }                     // y: ここまで
        return x;
    }                         // x: ここまで
}
