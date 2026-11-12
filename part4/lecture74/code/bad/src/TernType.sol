// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract TernType {
    function f(bool c, uint8 a, uint16 b) external pure returns (uint8) {
        uint8 r = c ? a : b;
        return r;
    }
}
