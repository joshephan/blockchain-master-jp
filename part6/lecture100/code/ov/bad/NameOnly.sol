// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract NameOnly {
    function f(uint256 a) external pure returns (uint256) {
        return a;
    }

    function f(uint256 b) external pure returns (uint256) {
        return b;
    }
}
