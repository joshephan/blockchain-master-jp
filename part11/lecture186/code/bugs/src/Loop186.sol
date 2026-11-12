// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Loop186 {
    // forの頭の++i: 0.8.22からコンパイラがオーバーフローチェックを外す
    function forLoop(uint256 n) external pure returns (uint256 s) {
        for (uint256 i = 0; i < n; ++i) {
            s ^= i;
        }
    }

    // 直接uncheckedで囲んだ版
    function forUnchecked(uint256 n) external pure returns (uint256 s) {
        for (uint256 i = 0; i < n;) {
            s ^= i;
            unchecked { ++i; }
        }
    }

    // whileの本体の++i: チェックそのまま
    function whileLoop(uint256 n) external pure returns (uint256 s) {
        uint256 i = 0;
        while (i < n) {
            s ^= i;
            ++i;
        }
    }
}
