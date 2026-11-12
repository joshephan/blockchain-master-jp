// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract RetOnly {
    function f(uint256 a) external pure returns (uint256) {
        return a;
    }

    function f(uint256 a) external pure returns (bool) {
        return a > 0;
    }
}
