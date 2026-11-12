// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Tern {
    function lit(bool c) external pure returns (uint256) {
        return 255 + (c ? 1 : 0);
    }

    function fixedLit(bool c) external pure returns (uint256) {
        return 255 + (c ? uint256(1) : 0);
    }

    function wrapped(bool c, uint256 a, int256 b) external pure returns (uint256) {
        return c ? a : uint256(b);
    }

    function mixedWidth(bool c, uint8 a, uint16 b) external pure returns (uint16) {
        return c ? a : b;
    }
}
