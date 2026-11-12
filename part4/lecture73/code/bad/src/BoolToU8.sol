// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract BoolToU8 {
    function f(bool a) external pure returns (uint8 b) {
        b = a;
    }
}
