// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Counter8 {
    // カウンターをuint8に変えた版、インクリメントはそのままチェック
    function countPlain(uint256 n) external pure returns (uint256 c) {
        for (uint8 i; i < n; ++i) {
            c += 1;
        }
    }

    // カウンターをuint8に変えた版、インクリメントをuncheckedで囲む
    function countWrapped(uint256 n) external pure returns (uint256 c) {
        for (uint8 i; i < n;) {
            c += 1;
            // i < nが先に弾くので++iはオーバーフローしない
            unchecked { ++i; }
        }
    }
}
