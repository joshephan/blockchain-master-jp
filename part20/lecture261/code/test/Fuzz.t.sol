// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {MarketMath} from "../src/MarketMath.sol";
import {IMarket} from "../src/IMarket.sol";

// ファズテスト(呼び出し一つにランダムな入力)。入力はMarketが実際に読む範囲に絞る
// 計算部品の性質二つ、丸めがマーケット側かを見る性質二つ(S-04)
contract FuzzTest is Base {
    function setUp() public {
        _deploy(0.05e18);
    }

    // 切り上げと切り捨ての差は0か1、切り捨てはあふれない
    function testFuzz_mulDivRounding(uint256 a, uint256 b, uint256 c) public pure {
        a = bound(a, 0, type(uint120).max);
        b = bound(b, 0, type(uint120).max);
        c = bound(c, 1, type(uint120).max);
        uint256 down = MarketMath.mulDivDown(a, b, c);
        uint256 up = MarketMath.mulDivUp(a, b, c);
        assertLe(up - down, 1);
        assertLe(down * c, a * b);
    }

    // 借りた比率が高いほど利率が下がらない(0~200%)
    function testFuzz_rateCurveMonotonic(uint256 u1, uint256 u2) public view {
        u1 = bound(u1, 0, 2e18);
        u2 = bound(u2, u1, 2e18);
        assertLe(MarketMath.borrowRate(u1, market.rateAtKink()), MarketMath.borrowRate(u2, market.rateAtKink()));
    }

    // 指数が1を超えたマーケットに預けてすぐ全部引き出しても、預けた量より多くは受け取れない
    function testFuzz_depositWithdrawNoGain(uint256 amount, uint256 wait) public {
        _openPosition();
        vm.warp(vm.getBlockTimestamp() + bound(wait, 1, 3650 days));
        amount = bound(amount, 2, 10_000e6);
        uint256 before = usd.balanceOf(dave);
        vm.startPrank(dave);
        try market.deposit(address(usd), amount) {
            market.withdrawAll(address(usd));
        } catch (bytes memory err) {
            assertEq(bytes4(err), IMarket.ZeroShares.selector);
        }
        vm.stopPrank();
        assertLe(usd.balanceOf(dave), before);
    }

    // 借りて同じブロックで全部返すと、借りた量より少なく返すことはない
    function testFuzz_borrowRepayNoGain(uint256 amount) public {
        _openPosition();
        vm.warp(vm.getBlockTimestamp() + 30 days);
        amount = bound(amount, 1, 40e6);
        uint256 before = usd.balanceOf(alice);
        vm.startPrank(alice);
        market.borrow(address(usd), amount);
        market.repay(address(usd), type(uint256).max);
        vm.stopPrank();
        assertLe(usd.balanceOf(alice), before);
    }

    // 何回かに分けて引き出し、残りを全部引き出しても、預けた量より多くは受け取れない(引く持ち分は切り上げ、S-04)
    function testFuzz_partialWithdrawNoGain(uint256 amount, uint256 pieces, uint256 wait) public {
        _openPosition();
        vm.warp(vm.getBlockTimestamp() + bound(wait, 365 days, 3650 days));
        vm.prank(alice);
        market.repay(address(usd), type(uint256).max);
        amount = bound(amount, 1000, 1000e6);
        pieces = bound(pieces, 2, 30);
        uint256 before = usd.balanceOf(dave);
        vm.startPrank(dave);
        market.deposit(address(usd), amount);
        uint256 have = market.depositOf(address(usd), dave);
        for (uint256 i = 0; i < pieces; i++) {
            uint256 part = have / (pieces + 1) + 1;
            if (market.depositOf(address(usd), dave) <= part) break;
            market.withdraw(address(usd), part);
        }
        market.withdrawAll(address(usd));
        vm.stopPrank();
        assertLe(usd.balanceOf(dave), before);
    }
}
