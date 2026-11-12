// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第116講のデモ: internal関数だけのライブラリ
library Percent {
    // 金額のpctパーセント、小数点以下切り上げ
    function part(uint256 amount, uint256 pct) internal pure returns (uint256) {
        return (amount * pct + 99) / 100;
    }
}

// 同じライブラリに呼ばない関数を19個足した版
library PercentMany {
    function part(uint256 amount, uint256 pct) internal pure returns (uint256) {
        return amount * pct / 100;
    }
    function f0(uint256 x) internal pure returns (uint256) { return x * 2 / 100 + 0; }
    function f1(uint256 x) internal pure returns (uint256) { return x * 3 / 100 + 1; }
    function f2(uint256 x) internal pure returns (uint256) { return x * 4 / 100 + 2; }
    function f3(uint256 x) internal pure returns (uint256) { return x * 5 / 100 + 3; }
    function f4(uint256 x) internal pure returns (uint256) { return x * 6 / 100 + 4; }
    function f5(uint256 x) internal pure returns (uint256) { return x * 7 / 100 + 5; }
    function f6(uint256 x) internal pure returns (uint256) { return x * 8 / 100 + 6; }
    function f7(uint256 x) internal pure returns (uint256) { return x * 9 / 100 + 7; }
    function f8(uint256 x) internal pure returns (uint256) { return x * 10 / 100 + 8; }
    function f9(uint256 x) internal pure returns (uint256) { return x * 11 / 100 + 9; }
    function f10(uint256 x) internal pure returns (uint256) { return x * 12 / 100 + 10; }
    function f11(uint256 x) internal pure returns (uint256) { return x * 13 / 100 + 11; }
    function f12(uint256 x) internal pure returns (uint256) { return x * 14 / 100 + 12; }
    function f13(uint256 x) internal pure returns (uint256) { return x * 15 / 100 + 13; }
    function f14(uint256 x) internal pure returns (uint256) { return x * 16 / 100 + 14; }
    function f15(uint256 x) internal pure returns (uint256) { return x * 17 / 100 + 15; }
    function f16(uint256 x) internal pure returns (uint256) { return x * 18 / 100 + 16; }
    function f17(uint256 x) internal pure returns (uint256) { return x * 19 / 100 + 17; }
    function f18(uint256 x) internal pure returns (uint256) { return x * 20 / 100 + 18; }
}
