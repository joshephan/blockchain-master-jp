// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {TwapFeed} from "./TwapFeed.sol";
import {ToyToken} from "./amm/ToyErc20.sol";
import {ToyAmm} from "./amm/ToyAmm.sol";

// 第198講のデモ: 清算で受け取ったCOL 432.35をプールに売るといくら残るか。プールの深さ(COL側の残高)だけを変えてみる
// 価格0.85、返したUSD 350、ボーナス5%。プールの手数料0.3%
contract Econ198Test is Test {
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);

    function _liquidateAndSell(uint256 poolCol) internal returns (uint256 seized, uint256 usdOut) {
        ToyToken col = new ToyToken(18);
        ToyToken usd = new ToyToken(6);
        Market market = new Market(address(this), Rate.wrap(0), Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        TwapFeed colFeed = new TwapFeed(1e18);
        market.setPriceFeed(address(col), colFeed);
        market.setPriceFeed(address(usd), new TwapFeed(1e18));
        vm.warp(vm.getBlockTimestamp() + 1 hours);

        col.mint(alice, 1000e18);
        usd.mint(bob, 1000e6);
        usd.mint(carol, 350e6);
        vm.startPrank(bob);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(usd), 1000e6);
        vm.stopPrank();
        vm.startPrank(alice);
        col.approve(address(market), type(uint256).max);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 700e6);
        vm.stopPrank();

        colFeed.setPrice(0.85e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);

        // 外のプール: COL poolCol個とUSD 0.85倍
        ToyAmm pool = new ToyAmm(col, usd, 30);
        col.mint(address(this), poolCol);
        usd.mint(address(this), poolCol * 85 / 100 / 1e12);
        col.approve(address(pool), type(uint256).max);
        usd.approve(address(pool), type(uint256).max);
        pool.addLiquidity(poolCol, poolCol * 85 / 100 / 1e12);

        vm.startPrank(carol);
        usd.approve(address(market), type(uint256).max);
        market.liquidate(alice, address(usd), address(col), 350e6);
        market.withdrawAll(address(col));
        seized = col.balanceOf(carol);
        col.approve(address(pool), type(uint256).max);
        usdOut = pool.swap(address(col), seized, 0);
        vm.stopPrank();
    }

    function test_profitByDepth() public {
        uint256[5] memory depth = [uint256(1_000_000e18), 100_000e18, 20_000e18, 5_000e18, 2_000e18];
        for (uint256 i = 0; i < 5; i++) {
            (uint256 seized, uint256 usdOut) = _liquidateAndSell(depth[i]);
            assertEq(seized, 432_352_941_176_470_588_235);
            int256 profit = int256(usdOut) - int256(350e6);
            console.log("pool COL %s, sold for USD(1e-6) %s", depth[i] / 1e18, usdOut);
            console.logInt(profit);
        }
    }
}
