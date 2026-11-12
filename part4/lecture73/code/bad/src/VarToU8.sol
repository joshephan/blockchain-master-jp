// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract VarToU8 {
    function f() external pure returns (uint8) {
        uint256 x = 5;
        uint8 y = x;
        return y;
    }
}
