// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Opt124 {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function seven() external pure returns (uint256) {
        uint256 x = 3;
        uint256 y = 4;
        return x + y;
    }
}
