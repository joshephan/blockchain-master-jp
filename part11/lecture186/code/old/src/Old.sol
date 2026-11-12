// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6 <0.9.0;

contract Old {
    function add8(uint8 a, uint8 b) external pure returns (uint8) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }
}
