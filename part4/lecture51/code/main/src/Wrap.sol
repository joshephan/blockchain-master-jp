// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Wrap {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    function addUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked { return a + b; }
    }

    function subUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked { return a - b; }
    }

    function mulUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked { return a * b; }
    }

    function mul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    function addInt8(int8 a, int8 b) external pure returns (int8) {
        return a + b;
    }
}
