// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract B4toB1 {
    function f(bytes4 a) external pure returns (bytes1 b) {
        b = a;
    }
}
