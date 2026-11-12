// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract CondFixed {
    function check(uint256 x, address a) external pure returns (uint256 r) {
        if (x != 0) {
            r += 1;
        }
        if (a != address(0)) {
            r += 2;
        }
    }
}
