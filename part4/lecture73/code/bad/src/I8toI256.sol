// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract I8toI256 {
    function f(int8 a) external pure returns (int256 b) {
        b = a;
    }
}
