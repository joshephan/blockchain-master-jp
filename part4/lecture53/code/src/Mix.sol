// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Mix {
    /// @param amount18 小数点以下18桁のトークン金額
    /// @param amount6  小数点以下6桁のトークン金額
    function total(uint256 amount18, uint256 amount6) external pure returns (uint256) {
        return amount18 + amount6;
    }

    // 倍率18の値二つを掛けるだけ
    function mulRaw(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    // 掛けてから10の18乗で割る
    function mulThenDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b / 1e18;
    }

    // 先に割ってから掛ける
    function divThenMul(uint256 a, uint256 b) external pure returns (uint256) {
        return a / 1e18 * b;
    }
}
