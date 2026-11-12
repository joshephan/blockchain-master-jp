// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// 第198講: 清算。aliceがCOL 1000(担保比率75、清算ライン80)を預けてUSD 700を借りたポジションで、COLの価格が下がる
// 利息0のマーケット(折れ点の利率0)で数字を固定。利息で清算ラインを超えるケースだけ年5%のマーケット
contract LiquidateTest is Test {
    StdToken col;
    StdToken usd;
    TwapFeed colFeed;
    Market market;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);
    address dave = address(0xDA7E);

    function setUp() public {
        _deploy(Rate.wrap(0));
    }

    function _deploy(Rate rate) internal {
        col = new StdToken("Collateral", "COL", 18, 1_000_000e18);
        usd = new StdToken("Dollar", "USD", 6, 1_000_000e6);
        market = new Market(address(this), rate, Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        colFeed = new TwapFeed(1e18);
        market.setPriceFeed(address(col), colFeed);
        market.setPriceFeed(address(usd), new TwapFeed(1e18));
        vm.warp(vm.getBlockTimestamp() + 1 hours);

        col.transfer(alice, 1000e18);
        usd.transfer(bob, 1000e6);
        usd.transfer(carol, 1000e6);
        usd.transfer(dave, 1000e6);
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
        vm.prank(carol);
        usd.approve(address(market), type(uint256).max);
        vm.prank(dave);
        usd.approve(address(market), type(uint256).max);
    }

    // 価格を変えてウィンドウ(30分)だけ進め、平均が新しい価格になるように
    function _price(uint256 p) internal {
        colFeed.setPrice(p);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
    }

    // 価格0.9: 借入上限675 < 借金700 < 清算ライン720。これ以上は借りられないが清算もされない
    function test_gapBand() public {
        _price(0.9e18);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 675e18, 701e18));
        market.borrow(address(usd), 1e6);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 720e18, 700e18));
        market.liquidate(alice, address(usd), address(col), 100e6);
    }

    // 価格0.85: 清算ライン680 < 借金700。350を返して367.5相当(5%多く)をCOLで受け取る
    function test_liquidateHalf() public {
        _price(0.85e18);
        assertEq(market.liquidationLimit(alice), 680e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 350e6);
        assertEq(market.debtOf(address(usd), alice), 350e6);
        assertEq(market.depositOf(address(col), carol), 432_352_941_176_470_588_235);
        assertEq(market.depositOf(address(col), alice), 567_647_058_823_529_411_765);
        assertEq(market.liquidationLimit(alice), 386e18);
        vm.prank(carol);
        market.withdrawAll(address(col));
        assertEq(col.balanceOf(carol), 432_352_941_176_470_588_235);
        assertEq(usd.balanceOf(carol), 650e6);
    }

    // 同じポジションを二番目に清算しようとする側は、もう清算ラインの下なのでリバート
    function test_secondLiquidatorReverts() public {
        _price(0.85e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 350e6);
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 386e18, 350e18));
        market.liquidate(alice, address(usd), address(col), 175e6);
        assertEq(usd.balanceOf(dave), 1000e6);
    }

    // 一度に借金の50%まで。担保に使っていない資産は受け取れない
    function test_closeFactorAndCollateralOnly() public {
        _price(0.85e18);
        vm.startPrank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.AboveCloseFactor.selector, 350e6, 351e6));
        market.liquidate(alice, address(usd), address(col), 351e6);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotCollateral.selector, address(usd)));
        market.liquidate(alice, address(usd), address(usd), 100e6);
        vm.stopPrank();
    }

    // 価格0.3: 担保の値300 < 借金700。350を返すと受け取るCOL 1225が預けた1000より多いのでリバート
    function test_underwaterSeizeTooLarge() public {
        _price(0.3e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.SeizeExceedsCollateral.selector, 1000e18, 1225e18));
        market.liquidate(alice, address(usd), address(col), 350e6);
    }

    // 凍結したマーケットでも清算はできる
    function test_liquidateWhenFrozen() public {
        _price(0.85e18);
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 350e6);
        assertEq(market.debtOf(address(usd), alice), 350e6);
    }

    // 年5%のマーケット。価格0.9のままでも1年の利息(借りた比率70%、年4.375%)で借金730.625が清算ライン720を超える
    function test_interestCrossesLine() public {
        _deploy(Rate.wrap(5e16));
        _price(0.9e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 720e18, 700_001_749e12)); // 30分の利息0.001749、切り上げ
        market.liquidate(alice, address(usd), address(col), 100e6);
        vm.warp(vm.getBlockTimestamp() + 365 days - 30 minutes); // 借りたときから1年
        assertEq(market.debtOf(address(usd), alice), 730_625_000);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 100e6);
    }
}
