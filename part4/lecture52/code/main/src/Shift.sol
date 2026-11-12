// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Shift {
    function mul2(uint8 x) external pure returns (uint8) {
        return x * 2;
    }

    function shl1(uint8 x) external pure returns (uint8) {
        return x << 1;
    }

    function sdiv2(int256 x) external pure returns (int256) {
        return x / 2;
    }

    function sshr1(int256 x) external pure returns (int256) {
        return x >> 1;
    }

    function shl(uint256 x, uint256 n) external pure returns (uint256) {
        return x << n;
    }
}
