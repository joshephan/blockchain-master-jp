// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, IPriceFeed, Ratio, Rate} from "../../src/Market.sol";
import {StdToken} from "../StdToken.sol";
import {TwapFeed} from "../TwapFeed.sol";

// 第56章のデモ共通のポジション: 第198講・第199講のテストと同じポジション(alice COL 1000を預けてUSD 700を借りる、bob USD 1000を預ける、利息0のマーケット)
// COLの価格の出どころだけテストごとに変えてつなぐ。USDの出どころは1.0固定のTwapFeed
abstract contract Base56 is Test {
    StdToken col;
    StdToken usd;
    Market market;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);

    function _open(IPriceFeed colFeed) internal {
        col = new StdToken("Collateral", "COL", 18, 1_000_000e18);
        usd = new StdToken("Dollar", "USD", 6, 1_000_000e6);
        market = new Market(address(this), Rate.wrap(0), Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        market.setPriceFeed(address(col), colFeed);
        market.setPriceFeed(address(usd), new TwapFeed(1e18));
    }

    function _positions() internal {
        col.transfer(alice, 1000e18);
        usd.transfer(bob, 1000e6);
        usd.transfer(carol, 1000e6);
        vm.startPrank(bob);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(usd), 1000e6);
        vm.stopPrank();
        vm.startPrank(alice);
        col.approve(address(market), type(uint256).max);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 700e6);
        vm.stopPrank();
        vm.prank(carol);
        usd.approve(address(market), type(uint256).max);
    }
}
