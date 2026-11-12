// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 計算だけをするライブラリ。internal関数だけなのでMarketのランタイムコードに入る(別のデプロイ・リンクなし)
// 状態を読みも書きもしない。丸めの方向はdesign/architecture.md 4節(S-04)
library MarketMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;
    uint256 internal constant KINK = 0.8e18; // 折れ点、借りた比率80%
    uint256 internal constant JUMP_RATE = 1e18; // 折れ点の後の傾き。借りた比率100%で年100%を足す

    // 借りた比率(倍率10の18乗)。預けた量が0なら0
    function utilization(uint256 borrows, uint256 deposits) internal pure returns (uint256) {
        if (deposits == 0) return 0;
        return borrows * WAD / deposits;
    }

    // 借りた比率に応じた年利率。rateAtKinkは折れ点での年利率
    function borrowRate(uint256 u, uint256 rateAtKink) internal pure returns (uint256) {
        if (u <= KINK) return rateAtKink * u / KINK;
        return rateAtKink + JUMP_RATE * (u - KINK) / (WAD - KINK);
    }

    // elapsed秒のあいだ年利率rateで付く利息(切り捨て)。複利は指数を掛けながら積む
    function interestFor(uint256 amount, uint256 rate, uint256 elapsed) internal pure returns (uint256) {
        return amount * rate * elapsed / SECONDS_PER_YEAR / WAD;
    }

    // a × b ÷ c 切り捨て
    function mulDivDown(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return a * b / c;
    }

    // a × b ÷ c 切り上げ
    function mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 x = a * b;
        return x == 0 ? 0 : (x - 1) / c + 1;
    }
}
