// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// 第199講のデモ: 上場した資産の数に応じてborrow・liquidateのガスがどれだけ増えるか。上限の計算が資産リストを全部回るため
contract Gas199Test is Test {
    address alice = address(0xA11CE);
    address carol = address(0xCA201);

    function _measure(uint256 extraAssets) internal returns (uint256 borrowGas, uint256 liquidateGas) {
        StdToken col = new StdToken("Collateral", "COL", 18, 1_000_000e18);
        StdToken usd = new StdToken("Dollar", "USD", 6, 1_000_000e6);
        Market market = new Market(address(this), Rate.wrap(0), Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        for (uint256 i = 0; i < extraAssets; i++) {
            market.addAsset(IERC20(address(new MockToken())), Ratio.wrap(50));
        }
        TwapFeed colFeed = new TwapFeed(1e18);
        market.setPriceFeed(address(col), colFeed);
        market.setPriceFeed(address(usd), new TwapFeed(1e18));
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(usd), 1000e6);
        col.transfer(alice, 1000e18);
        usd.transfer(carol, 1000e6);
        vm.startPrank(alice);
        col.approve(address(market), type(uint256).max);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 700e6);
        borrowGas = vm.lastCallGas().gasTotalUsed;
        vm.stopPrank();
        colFeed.setPrice(0.85e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        vm.startPrank(carol);
        usd.approve(address(market), type(uint256).max);
        market.liquidate(alice, address(usd), address(col), 350e6);
        liquidateGas = vm.lastCallGas().gasTotalUsed;
        vm.stopPrank();
    }

    function test_gasByAssetCount() public {
        uint256[4] memory extra = [uint256(0), 18, 98, 498];
        for (uint256 i = 0; i < 4; i++) {
            (uint256 b, uint256 l) = _measure(extra[i]);
            console.log("assets %s: borrow gas %s, liquidate gas %s", extra[i] + 2, b, l);
        }
    }
}
