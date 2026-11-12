// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MixType {
    function f(uint8 a, uint16 b) external pure returns (uint8) {
        uint8 c = a + b;
        return c;
    }
}
