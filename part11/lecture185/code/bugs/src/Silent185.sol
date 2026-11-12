// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ソースはそのままコンパイルされるのに、バージョンによって答えが変わった箇所
contract Silent185 {
    // 0.5.0: 符号付きの右シフトを負の無限大の方向に丸める
    function shiftSigned(int256 x) external pure returns (int256) {
        return x >> 1;
    }

    // 0.6.0: べき乗の結果の型が底の型
    function powBase(uint8 b, uint256 e) external pure returns (uint256) {
        return b ** e;
    }

    // 0.7.0: リテラルを変数の分だけシフトするとuint256で計算
    function shiftLiteral(uint8 n) external pure returns (uint256) {
        return 1 << n;
    }
}
