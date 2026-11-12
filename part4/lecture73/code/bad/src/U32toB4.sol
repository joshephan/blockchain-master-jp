// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract U32toB4 {
    function f(uint32 a) external pure returns (bytes4 b) {
        b = a;
    }
}
