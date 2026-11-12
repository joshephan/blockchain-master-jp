// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MarketMath} from "../src/MarketMath.sol";

// 設計文書4節の計算部品の確認。Marketができる前に曲線の値と丸めの方向を先に固定する
contract MathTest is Test {
    // 折れ点の利率5%: 借りた比率0・20・40・60・80・85・90・95・100% → 年0・1.25・2.5・3.75・5・30・55・80・105%
    function test_rateCurveTable() public pure {
        uint256[9] memory u = [uint256(0), 0.2e18, 0.4e18, 0.6e18, 0.8e18, 0.85e18, 0.9e18, 0.95e18, 1e18];
        uint256[9] memory want = [uint256(0), 0.0125e18, 0.025e18, 0.0375e18, 0.05e18, 0.3e18, 0.55e18, 0.8e18, 1.05e18];
        for (uint256 i = 0; i < 9; i++) {
            assertEq(MarketMath.borrowRate(u[i], 0.05e18), want[i]);
        }
    }

    // 借金500、借りた比率50%(年3.125%)、1年 → 利息15.625
    function test_interestOneYear() public pure {
        uint256 rate = MarketMath.borrowRate(MarketMath.utilization(500e6, 1000e6), 0.05e18);
        assertEq(rate, 0.03125e18);
        assertEq(MarketMath.interestFor(500e6, rate, 365 days), 15_625_000);
    }

    // 丸めの方向: 切り捨てと切り上げは余りがあるときだけ1の差
    function test_roundingDirections() public pure {
        assertEq(MarketMath.mulDivDown(10, 1, 3), 3);
        assertEq(MarketMath.mulDivUp(10, 1, 3), 4);
        assertEq(MarketMath.mulDivDown(9, 1, 3), 3);
        assertEq(MarketMath.mulDivUp(9, 1, 3), 3);
        assertEq(MarketMath.mulDivUp(0, 5, 3), 0);
    }

    // 預けた量が0なら借りた比率は0(0で割らない)
    function test_utilizationEmpty() public pure {
        assertEq(MarketMath.utilization(0, 0), 0);
    }
}
