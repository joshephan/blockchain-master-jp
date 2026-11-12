// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console} from "forge-std/Test.sol";
import {Base56} from "./Base56.sol";
import {RoundAggregator} from "./RoundAggregator.sol";
import {RoundFeed} from "./RoundFeed.sol";
import {TwapFeed} from "../TwapFeed.sol";
import {IMarket} from "../../src/IMarket.sol";

// 第205講: ハートビート1時間 + 余裕10分 = maxAge 4200秒(講義用の設計値)。それより古い答えは使わない
contract Stale205Test is Base56 {
    RoundAggregator agg;
    RoundFeed feed;
    uint256 t0;

    function setUp() public {
        vm.warp(1_700_000_000);
        agg = new RoundAggregator(8, 1e8);
        feed = new RoundFeed(agg, 1 hours + 10 minutes);
        _open(feed);
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        agg.transmit(1e8);
        t0 = vm.getBlockTimestamp();
        _positions();
    }

    // 4200秒目は使う、4201秒目はStaleRound
    function test_maxAgeBoundary() public {
        vm.warp(t0 + 4200);
        assertEq(market.priceOf(address(col)), 1e18);
        vm.warp(t0 + 4201);
        vm.expectRevert(abi.encodeWithSelector(RoundFeed.StaleRound.selector, t0, 4200));
        market.priceOf(address(col));
    }

    // 古い答え: 借り入れ・担保の引き出し・清算は止まり、返済と担保でない資産の引き出しはできる。新しい答えが来るとまた借りられる
    function test_staleStopsBorrowNotRepay() public {
        vm.warp(t0 + 2 hours);
        bytes memory stale = abi.encodeWithSelector(RoundFeed.StaleRound.selector, t0, 4200);
        vm.startPrank(alice);
        vm.expectRevert(stale);
        market.borrow(address(usd), 1e6);
        vm.expectRevert(stale);
        market.withdraw(address(col), 1e18);
        market.repay(address(usd), 100e6);
        vm.stopPrank();
        vm.prank(carol);
        vm.expectRevert(stale);
        market.liquidate(alice, address(usd), address(col), 1e6);
        vm.prank(bob);
        market.withdraw(address(usd), 300e6);
        agg.transmit(1e8);
        vm.prank(alice);
        market.borrow(address(usd), 50e6);
        assertEq(market.debtOf(address(usd), alice), 650e6);
    }

    // 外の価格が60分かけて1.0 → 0.9に均等に下がるとき(1分ごと)、偏差のしきい値d bps・ハートビート1時間で答えを書くと
    // 書かれた回数、フィードと外の価格の最大の差(フィードの値に対するbps)、60分目のフィードの値、同じ階段を30分平均した値(60分目)
    function _simulate(uint256 d) internal returns (uint256 rounds, uint256 maxGapBps, uint256 feedAt60, uint256 twapAt60) {
        RoundAggregator a = new RoundAggregator(8, 1e8);
        TwapFeed tw = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 1 hours); // 平均に使う記録を30分以上
        tw.setPrice(1e18);
        uint256 last = 1e8;
        uint256 lastAt = vm.getBlockTimestamp();
        for (uint256 m = 1; m <= 60; m++) {
            vm.warp(vm.getBlockTimestamp() + 1 minutes);
            uint256 p = 1e8 - m * 1e7 / 60; // 外の価格(桁数8)
            uint256 diff = last > p ? last - p : p - last;
            if (diff * 10_000 >= d * last || vm.getBlockTimestamp() - lastAt >= 1 hours) {
                a.transmit(int256(p));
                tw.setPrice(p * 1e10);
                last = p;
                lastAt = vm.getBlockTimestamp();
                rounds++;
            }
            uint256 gap = (last > p ? last - p : p - last) * 10_000 / last;
            if (gap > maxGapBps) maxGapBps = gap;
        }
        feedAt60 = last * 1e10;
        twapAt60 = (tw.cumulativePrice(0) - tw.cumulativePrice(30 minutes)) / 30 minutes;
    }

    function test_deviationLag() public {
        (uint256 r50, uint256 g50, uint256 f50, uint256 tw50) = _simulate(50);
        (uint256 r200, uint256 g200, uint256 f200, uint256 tw200) = _simulate(200);
        console.log("d=50bps rounds", r50, "max gap bps", g50);
        console.log("  feed at 60min", f50, "30min average at 60min", tw50);
        console.log("d=200bps rounds", r200, "max gap bps", g200);
        console.log("  feed at 60min", f200, "30min average at 60min", tw200);
        assertLt(g50, 50);
        assertLt(g200, 200);
    }

    // 一気に1.0 → 0.5: プッシュ型のフィードは同じブロックで0.5。担保500 < 借金700なのでその場で水面下(借金全部まで清算)
    function test_gapDownStillUnderwater() public {
        agg.transmit(0.5e8);
        assertEq(market.liquidationLimit(alice), 400e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 700e6);
        assertEq(usd.balanceOf(carol), 1000e6 - 476_190_477);
        assertEq(market.debtOf(address(usd), alice), 223_809_523);
        market.writeOffBadDebt(alice, address(usd));
        assertEq(market.depositOf(address(usd), bob), 776_190_477);
    }
}
