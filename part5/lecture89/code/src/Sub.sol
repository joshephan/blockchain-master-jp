// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Sub {
    function gapChecked(uint256 a, uint256 b) external pure returns (uint256) {
        if (a >= b) {
            return a - b;
        }
        return 0;
    }

    function gapUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        if (a >= b) {
            // すぐ上のifでa >= bを確認したので、a - bは0を下回らない
            unchecked { return a - b; }
        }
        return 0;
    }
}
