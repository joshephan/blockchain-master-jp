// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Wrap {
    function addChecked(uint8 a, uint8 b) external pure returns (uint8) {
        return a + b;
    }

    function addUnchecked(uint8 a, uint8 b) external pure returns (uint8) {
        unchecked { return a + b; }
    }

    function divUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked { return a / b; }
    }

    function modUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked { return a % b; }
    }

    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        return a + b;
    }

    function callInside(uint8 a, uint8 b) external pure returns (uint8) {
        unchecked { return add(a, b); }
    }
}
