// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6 <0.9.0;

contract Old2 {
    function div(uint256 a, uint256 b) external pure returns (uint256) {
        return a / b;
    }

    function divI8(int8 a, int8 b) external pure returns (int8) {
        return a / b;
    }
}
