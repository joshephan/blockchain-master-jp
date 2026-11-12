// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract U8toI16 {
    function f(uint8 a) external pure returns (int16 b) {
        b = a;
    }
}
