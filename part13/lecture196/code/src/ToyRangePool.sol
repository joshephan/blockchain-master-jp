// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// 第196講の講義用の集中流動性プール。ポジション一つ、区間一つ、手数料・トークンの移転は省略(帳簿の数字だけ)
// 価格は小数なので√価格を倍率10の18乗の整数で持ち歩く
contract ToyRangePool {
    uint256 internal constant ONE = 1e18;

    uint256 public immutable liquidity; // L
    uint256 public immutable sqrtLower; // √(区間の下の価格)
    uint256 public immutable sqrtUpper; // √(区間の上の価格)
    uint256 public sqrtPrice; // √(今の価格)、token0一個がtoken1何個かの平方根

    error OutOfRange(uint256 sqrtNext, uint256 sqrtLower, uint256 sqrtUpper);

    constructor(uint256 l, uint256 sqrtLower_, uint256 sqrtUpper_, uint256 sqrtPrice_) {
        liquidity = l;
        sqrtLower = sqrtLower_;
        sqrtUpper = sqrtUpper_;
        sqrtPrice = sqrtPrice_;
    }

    // 今の価格でこのポジションに実際に入っている量
    // amount0 = L × (1/√p − 1/√pb), amount1 = L × (√p − √pa)
    function amounts() public view returns (uint256 amount0, uint256 amount1) {
        // L × (√pb − √p) / (√p × √pb)にまとめて引き算を一回だけ行う(切り捨て)
        amount0 = Math.mulDiv(Math.mulDiv(liquidity, sqrtUpper - sqrtPrice, sqrtUpper), ONE, sqrtPrice);
        amount1 = Math.mulDiv(liquidity, sqrtPrice - sqrtLower, ONE);
    }

    // token1を入れてtoken0を受け取る。√価格がΔy / Lだけ上がる
    function swap1For0(uint256 amountIn) external returns (uint256 out0) {
        uint256 next = sqrtPrice + Math.mulDiv(amountIn, ONE, liquidity);
        if (next > sqrtUpper) revert OutOfRange(next, sqrtLower, sqrtUpper);
        // 渡す量 L × (√p' − √p) / (√p × √p')は切り捨て
        out0 = Math.mulDiv(Math.mulDiv(liquidity, next - sqrtPrice, next), ONE, sqrtPrice);
        sqrtPrice = next;
    }

    // token0を入れてtoken1を受け取る。1/√価格がΔx / Lだけ上がる
    function swap0For1(uint256 amountIn) external returns (uint256 out1) {
        // √p' = L × √p / (L + Δx × √p)
        uint256 next =
            Math.mulDiv(liquidity, sqrtPrice, liquidity + Math.mulDiv(amountIn, sqrtPrice, ONE), Math.Rounding.Ceil);
        if (next < sqrtLower) revert OutOfRange(next, sqrtLower, sqrtUpper);
        out1 = Math.mulDiv(liquidity, sqrtPrice - next, ONE);
        sqrtPrice = next;
    }

    // 今の価格(倍率10の18乗) = √p × √p
    function price() external view returns (uint256) {
        return Math.mulDiv(sqrtPrice, sqrtPrice, ONE);
    }
}
