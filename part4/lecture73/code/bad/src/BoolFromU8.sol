// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract BoolFromU8 {
    function f(uint8 x) external pure returns (bool) {
        return bool(x);
    }
}
