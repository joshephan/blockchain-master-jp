// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第49章の確認テスト。Marketのsrcは変えない。uint64(block.timestamp)の二行(MarketMath 33・41)の範囲を確認
contract Cast49Test is Test {
    Market market;
    MockToken token;

    function setUp() public {
        market = new Market(address(this), Rate.wrap(0), Ratio.wrap(80));
        token = new MockToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(50));
    }

    // 今の時刻の近くでは切り詰められない
    function test_lastUpdateFitsNow() public {
        vm.warp(1_800_000_000);
        market.deposit(address(token), 100);
        (,, uint64 last,) = market.positions(address(token), address(this));
        console.log("lastUpdate", last);
        assertEq(last, 1_800_000_000);
    }

    // 2**64秒を超えると変換が黙って切り詰められる(Panicなし)。elapsedOfが2**64分ずれる
    function test_lastUpdateTruncatesPast2pow64() public {
        uint256 t = uint256(type(uint64).max) + 6;
        vm.warp(t);
        market.deposit(address(token), 100);
        (,, uint64 last,) = market.positions(address(token), address(this));
        console.log("lastUpdate", last);
        console.log("elapsedOf ", market.elapsedOf(address(token), address(this)));
        assertEq(last, 5);
    }
}
