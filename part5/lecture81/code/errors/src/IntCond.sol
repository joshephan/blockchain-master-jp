// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract IntCond {
    function check(uint256 x, address a) external pure returns (uint256 r) {
        if (x) {
            r += 1;
        }
        if (a) {
            r += 2;
        }
    }
}
