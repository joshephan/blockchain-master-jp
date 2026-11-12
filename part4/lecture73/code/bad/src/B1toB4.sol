// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract B1toB4 {
    function f(bytes1 a) external pure returns (bytes4 b) {
        b = a;
    }
}
