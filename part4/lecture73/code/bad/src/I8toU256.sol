// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract I8toU256 {
    function f(int8 a) external pure returns (uint256 b) {
        b = a;
    }
}
