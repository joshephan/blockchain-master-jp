// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MixBranch {
    function f(bool c, uint256 a, int256 b) external pure returns (uint256) {
        return c ? a : b;
    }
}
