// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// 第199講: 極限の状況。第198講のテストと同じポジション(alice COL 1000、USD 700を借りる、bob USD 1000を預ける、利息0のマーケット)
// 価格が借金より深く下がったポジション、平均価格が遅れて追いつくあいだ、価格の出どころが止まったあいだ
contract BadDebtTest is Test {
    StdToken col;
    StdToken usd;
    TwapFeed colFeed;
    Market market;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);
    address dave = address(0xDA7E);

    function setUp() public {
        col = new StdToken("Collateral", "COL", 18, 1_000_000e18);
        usd = new StdToken("Dollar", "USD", 6, 1_000_000e6);
        market = new Market(address(this), Rate.wrap(0), Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        colFeed = new TwapFeed(1e18);
        market.setPriceFeed(address(col), colFeed);
        market.setPriceFeed(address(usd), new TwapFeed(1e18));
        vm.warp(vm.getBlockTimestamp() + 1 hours);

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

    function _price(uint256 p) internal {
        colFeed.setPrice(p);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
    }

    // 価格0.3: 担保の値300 < 借金700。借金全部まで返せて、受け取る担保は預けた1000に減り、返す量は300 / 1.05
    function test_underwaterFullLiquidation() public {
        _price(0.3e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.AboveCloseFactor.selector, 700e6, 701e6));
        market.liquidate(alice, address(usd), address(col), 701e6);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 700e6);
        assertEq(usd.balanceOf(carol), 1000e6 - 285_714_286);
        assertEq(market.depositOf(address(col), carol), 1000e18);
        assertEq(market.depositOf(address(col), alice), 0);
        assertEq(market.debtOf(address(usd), alice), 414_285_714);
    }

    // 担保が残っていない借金414.285714を消すとbobの持ち分が1000から585.714286に。MarketのUSD残高と同じ
    function test_writeOffSharesLoss() public {
        _price(0.3e18);
        vm.expectRevert(abi.encodeWithSelector(IMarket.HasCollateral.selector, 300e18));
        market.writeOffBadDebt(alice, address(usd));
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 700e6);
        vm.prank(dave);
        vm.expectEmit(address(market));
        emit IMarket.BadDebtWrittenOff(address(usd), alice, 414_285_714);
        market.writeOffBadDebt(alice, address(usd));
        assertEq(market.debtOf(address(usd), alice), 0);
        assertEq(market.depositOf(address(usd), bob), 585_714_286);
        assertEq(usd.balanceOf(address(market)), 585_714_286);
        vm.prank(bob);
        market.withdrawAll(address(usd));
        assertEq(usd.balanceOf(address(market)), 0);
    }

    // 価格が1.0から0.5に一気に下がる。平均は30分かけて追いつく
    // 0分: 清算ライン800(清算されない) / 10分: 666.67(清算される)。このとき350を返して受け取るCOL 441は平均0.833で数えた量なので
    // 実際の価格0.5では220.5相当。返した350より少なく、清算する側が損をする
    function test_twapLagUnprofitable() public {
        colFeed.setPrice(0.5e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 800e18, 700e18));
        market.liquidate(alice, address(usd), address(col), 350e6);
        vm.warp(vm.getBlockTimestamp() + 10 minutes);
        assertEq(market.priceOf(address(col)), 833_333_333_333_333_333);
        assertEq(market.liquidationLimit(alice), 666_666_666_666_666_666_400);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 350e6);
        uint256 got = market.depositOf(address(col), carol);
        assertEq(got, 441_000_000_000_000_000_176);
        assertEq(got * 0.5e18 / 1e18, 220_500_000_000_000_000_088);
    }

    // 誰も清算しないまま30分たつと平均も0.5。担保の値500 < 借金700なので借金全部まで返してCOL 1000を全部受け取る
    // 返す量500 / 1.05 = 476.190477、残る借金223.809523を消すとbobの持ち分776.190477 = MarketのUSD残高
    function test_lateLiquidationBadDebt() public {
        _price(0.5e18);
        assertEq(market.liquidationLimit(alice), 400e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 700e6);
        assertEq(market.debtOf(address(usd), alice), 223_809_523);
        market.writeOffBadDebt(alice, address(usd));
        assertEq(market.depositOf(address(usd), bob), 776_190_477);
        assertEq(usd.balanceOf(address(market)), 776_190_477);
    }

    // 価格の出どころが止まる: 返済と担保でない資産の引き出しはできる。借り入れ・担保の引き出し・清算はリバート
    function test_feedStopped() public {
        colFeed.stop();
        vm.startPrank(alice);
        market.repay(address(usd), 100e6);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.withdraw(address(col), 1e18);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.borrow(address(usd), 1e6);
        vm.stopPrank();
        vm.prank(carol);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.liquidate(alice, address(usd), address(col), 100e6);
        vm.prank(bob);
        market.withdraw(address(usd), 300e6);
        assertEq(market.debtOf(address(usd), alice), 600e6);
    }
}
