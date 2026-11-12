// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract U8toU256 {
    function f(uint8 a) external pure returns (uint256 b) {
        b = a;
    }
}
