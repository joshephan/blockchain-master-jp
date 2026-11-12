// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console} from "forge-std/Test.sol";
import {Base56} from "./Base56.sol";
import {RoundAggregator} from "./RoundAggregator.sol";
import {RoundFeed} from "./RoundFeed.sol";
import {IAggregatorV3} from "./IAggregatorV3.sol";
import {ToyToken} from "../amm/ToyErc20.sol";
import {ToyAmm} from "../amm/ToyAmm.sol";

// 第204講: プッシュ型のフィード(桁数8)をアダプターでMarketにつなぐ。Marketのコードはそのまま
contract Feed204Test is Base56 {
    RoundAggregator agg;
    RoundFeed feed;

    function setUp() public {
        vm.warp(1_700_000_000);
        agg = new RoundAggregator(8, 1e8);
        feed = new RoundFeed(agg, 1 hours + 10 minutes);
        _open(feed);
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        agg.transmit(1e8);
        _positions();
    }

    // 答え1.00000000(桁数8) → Marketの価格1e18、上限750。0.85を書くと同じブロックで0.85、清算ライン680
    function test_pushedPriceNoLag() public {
        assertEq(market.priceOf(address(col)), 1e18);
        (uint256 limit,) = market.accountHealth(alice);
        assertEq(limit, 750e18);
        agg.transmit(0.85e8);
        assertEq(market.priceOf(address(col)), 0.85e18);
        assertEq(market.liquidationLimit(alice), 680e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 350e6);
        assertEq(market.debtOf(address(usd), alice), 350e6);
    }

    // 桁数8と18のフィードが同じ1.0ならアダプターの値も同じ
    function test_decimalsScale() public {
        RoundAggregator a18 = new RoundAggregator(18, 1e18);
        RoundAggregator a8 = new RoundAggregator(8, 1e8);
        assertEq(new RoundFeed(a18, 1 hours).latestPrice(), 1e18);
        assertEq(new RoundFeed(a8, 1 hours).latestPrice(), 1e18);
    }

    // 答えが0以下ならリバート。借り入れは止まり返済はできる
    function test_rejectsNonPositive() public {
        agg.transmit(0);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(RoundFeed.BadAnswer.selector, int256(0)));
        market.borrow(address(usd), 1e6);
        agg.transmit(-1);
        vm.expectRevert(abi.encodeWithSelector(RoundFeed.BadAnswer.selector, int256(-1)));
        market.priceOf(address(col));
        vm.prank(alice);
        market.repay(address(usd), 100e6);
        assertEq(market.debtOf(address(usd), alice), 600e6);
    }

    // updatedAt 0(終わっていないラウンド)はリバート
    function test_rejectsIncompleteRound() public {
        agg.setRound(1e8, 0);
        vm.expectRevert(abi.encodeWithSelector(RoundFeed.IncompleteRound.selector, uint80(3)));
        market.priceOf(address(col));
    }

    // 符号付きの-1をuint256に変えるとオーバーフロー検査なしで2の256乗 - 1
    function test_castWraps() public pure {
        int256 x = -1;
        assertEq(uint256(x), type(uint256).max);
    }

    // フィードの値で受け取る最小量を決めると、プールの価格がフィードから離れた交換はリバートする
    function test_minOutFromFeed() public {
        ToyToken c = new ToyToken(18);
        ToyToken u = new ToyToken(18);
        ToyAmm pool = new ToyAmm(c, u, 30);
        c.mint(address(this), 13_100e18);
        u.mint(address(this), 10_000e18);
        c.approve(address(pool), type(uint256).max);
        u.approve(address(pool), type(uint256).max);
        pool.addLiquidity(10_000e18, 10_000e18);
        pool.swap(address(c), 3000e18, 0); // 誰かがCOL 3000を売ったあとのプール
        uint256 minOut = 100e18 * feed.latestPrice() / 1e18 * 99 / 100;
        console.log("pool spot after sale", pool.spotPrice());
        console.log("quote for 100 COL", pool.quote(address(c), 100e18));
        console.log("minOut from feed", minOut);
        vm.expectRevert(abi.encodeWithSelector(ToyAmm.Slippage.selector, pool.quote(address(c), 100e18), minOut));
        pool.swap(address(c), 100e18, minOut);
    }
}
