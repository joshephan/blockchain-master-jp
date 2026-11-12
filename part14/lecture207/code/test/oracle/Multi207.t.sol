// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console} from "forge-std/Test.sol";
import {Base56} from "./Base56.sol";
import {RoundAggregator} from "./RoundAggregator.sol";
import {RoundFeed} from "./RoundFeed.sol";
import {MedianFeed} from "./MedianFeed.sol";
import {FallbackFeed} from "./FallbackFeed.sol";
import {TwapFeed} from "../TwapFeed.sol";
import {IPriceFeed} from "../../src/MarketTypes.sol";

// 第207講: 出どころ三つの中央値、主の出どころと予備の出どころ。アダプターをMarketに一度つなぎ、Marketのコードはそのまま
contract Multi207Test is Base56 {
    RoundAggregator a;
    RoundAggregator b;
    RoundAggregator c;
    RoundFeed fa;
    RoundFeed fb;
    RoundFeed fc;
    TwapFeed spare; // 予備の出どころ: 30分平均を出す側(プール平均のまね)

    function _feeds() internal {
        vm.warp(1_700_000_000);
        a = new RoundAggregator(8, 1e8);
        b = new RoundAggregator(8, 1e8);
        c = new RoundAggregator(8, 1e8);
        fa = new RoundFeed(a, 1 hours + 10 minutes);
        fb = new RoundFeed(b, 1 hours + 10 minutes);
        fc = new RoundFeed(c, 1 hours + 10 minutes);
        spare = new TwapFeed(1e18);
    }

    function _start() internal {
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        a.transmit(1e8);
        b.transmit(1e8);
        c.transmit(1e8);
        _positions();
    }

    function _avg(IPriceFeed f) internal view returns (uint256) {
        return (f.cumulativePrice(0) - f.cumulativePrice(30 minutes)) / 30 minutes;
    }

    // 三つのうち一つが16.0でもMarketの価格は1.0。一つが1.01になれば1.01
    function test_medianIgnoresOneOutlier() public {
        _feeds();
        _open(new MedianFeed(fa, fb, fc));
        _start();
        c.transmit(16e8);
        assertEq(market.priceOf(address(col)), 1e18);
        (uint256 limit,) = market.accountHealth(alice);
        assertEq(limit, 750e18);
        b.transmit(1.01e8);
        assertEq(market.priceOf(address(col)), 1.01e18);
    }

    // 出どころ二つが同じフィードを読むと、そのフィード一つが16.0になったとき中央値も16.0
    function test_sameUpstreamCountsOnce() public {
        _feeds();
        RoundFeed fa2 = new RoundFeed(a, 1 hours + 10 minutes);
        MedianFeed m = new MedianFeed(fa, fa2, fc);
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        a.transmit(16e8);
        c.transmit(1e8);
        assertEq(_avg(m), 16e18);
    }

    // 中央値は三つ全部そろって出す。一つが古くなるとMarketの価格の読み取りが止まる
    function test_medianStopsIfOneStale() public {
        _feeds();
        _open(new MedianFeed(fa, fb, fc));
        _start();
        uint256 t = vm.getBlockTimestamp();
        vm.warp(t + 2 hours);
        a.transmit(1e8);
        b.transmit(1e8);
        vm.expectRevert(abi.encodeWithSelector(RoundFeed.StaleRound.selector, t, 4200));
        market.priceOf(address(col));
    }

    // 主の出どころが古くなると予備の出どころの30分平均に切り替わる
    function test_fallbackUsesSpare() public {
        _feeds();
        FallbackFeed f = new FallbackFeed(fa, spare);
        _open(f);
        _start();
        vm.warp(vm.getBlockTimestamp() + 2 hours);
        spare.setPrice(0.9e18);
        vm.warp(vm.getBlockTimestamp() + 10 minutes);
        assertEq(address(f.pick()), address(spare));
        uint256 p = market.priceOf(address(col));
        console.log("fallback price after 10min of 0.9", p);
        assertEq(p, _avg(spare));
    }

    // 両方生きているのに2%より開いたらリバート。借り入れは止まり返済はできる
    function test_fallbackDiverged() public {
        _feeds();
        _open(new FallbackFeed(fa, spare));
        _start();
        a.transmit(0.95e8);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FallbackFeed.Diverged.selector, 0.95e18, 1e18));
        market.borrow(address(usd), 1e6);
        vm.prank(alice);
        market.repay(address(usd), 100e6);
        a.transmit(0.985e8);
        assertEq(market.priceOf(address(col)), 0.985e18);
    }

    // 両方リバートしたらNoSource
    function test_fallbackNoSource() public {
        _feeds();
        _open(new FallbackFeed(fa, spare));
        _start();
        vm.warp(vm.getBlockTimestamp() + 2 hours);
        spare.stop();
        vm.expectRevert(FallbackFeed.NoSource.selector);
        market.priceOf(address(col));
    }

    // 出どころの形ごとに、aliceがUSD 10を追加で借りるガス
    function _borrowGas(IPriceFeed f) internal returns (uint256 used) {
        _open(f);
        _start();
        vm.prank(alice);
        uint256 g = gasleft();
        market.borrow(address(usd), 10e6);
        used = g - gasleft();
    }

    function test_gasBySource() public {
        _feeds();
        uint256 one = _borrowGas(fa);
        _feeds();
        uint256 twap = _borrowGas(new TwapFeed(1e18));
        _feeds();
        uint256 med = _borrowGas(new MedianFeed(fa, fb, fc));
        _feeds();
        uint256 fb2 = _borrowGas(new FallbackFeed(fa, spare));
        console.log("borrow gas RoundFeed", one);
        console.log("borrow gas TwapFeed", twap);
        console.log("borrow gas MedianFeed", med);
        console.log("borrow gas FallbackFeed", fb2);
    }
}
