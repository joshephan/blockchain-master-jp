// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {IMarket} from "../src/IMarket.sol";

// 機能要件F-01~F-10。テスト名の頭の番号がdesign/requirements.mdの要件番号
// 数字は前の版のテストと同じポジションで同じ値が出るかを見る
contract FunctionalTest is Base {
    function setUp() public {
        _deploy(0);
    }

    // 折れ点5%のマーケット。借金500(借りた比率50%、年3.125%)1年 → 515.625、預けた1000 → 1015.625。全部返して全部引き出すと金庫は0
    function test_F01_depositEarnsInterest() public {
        _deploy(0.05e18);
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 500e6);
        vm.stopPrank();
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(market.debtOf(address(usd), alice), 515_625_000);
        assertEq(market.depositOf(address(usd), bob), 1_015_625_000);
        vm.prank(alice);
        market.repay(address(usd), type(uint256).max);
        vm.prank(bob);
        market.withdrawAll(address(usd));
        assertEq(usd.balanceOf(bob), 10_015_625_000);
        assertEq(usd.balanceOf(address(market)), 0);
    }

    // 貸し出した分は引き出せない: 700借りたあとbob 400 → InsufficientLiquidity(300, 400)、300はできる
    function test_F02_withdrawUpToCash() public {
        _openPosition();
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientLiquidity.selector, 300e6, 400e6));
        market.withdraw(address(usd), 400e6);
        vm.prank(bob);
        market.withdraw(address(usd), 300e6);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientDeposit.selector, 700e6, 701e6));
        market.withdraw(address(usd), 701e6);
    }

    // 借金があれば担保をオフにできない(0, 700)、COL 60の引き出しは上限705の内側なのでできる、100は675 < 700なのでできない
    function test_F03_collateralToggle() public {
        _openPosition();
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 0, 700e18));
        market.setCollateral(address(col), false);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 675e18, 700e18));
        market.withdraw(address(col), 100e18);
        market.withdraw(address(col), 60e18);
        vm.stopPrank();
        (uint256 limit, uint256 debt) = market.accountHealth(alice);
        assertEq(limit, 705e18);
        assertEq(debt, 700e18);
    }

    // COL 1000 × 1.0 × 75% = 750。751 → InsufficientCollateral(750, 751)、750はできる
    function test_F04_borrowWithinLimit() public {
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 750e18, 751e18));
        market.borrow(address(usd), 751e6);
        market.borrow(address(usd), 750e6);
        vm.stopPrank();
    }

    // 1000を払うと借金700だけ受け取る。もう一度1 → NoDebt
    function test_F05_repayCapsAtDebt() public {
        _openPosition();
        uint256 before = usd.balanceOf(alice);
        vm.prank(alice);
        market.repay(address(usd), 1000e6);
        assertEq(before - usd.balanceOf(alice), 700e6);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NoDebt.selector, address(usd)));
        market.repay(address(usd), 1);
    }

    // 折れ点5%のマーケットで借りた比率0・50・80・90・100% → 年0・3.125・5・55・105%
    function test_F06_rateCurve() public {
        _deploy(0.05e18);
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.startPrank(alice);
        market.deposit(address(col), 10_000e18);
        market.setCollateral(address(col), true);
        assertEq(market.borrowRate(address(usd)), 0);
        market.borrow(address(usd), 500e6);
        assertEq(market.borrowRate(address(usd)), 0.03125e18);
        market.borrow(address(usd), 300e6);
        assertEq(market.borrowRate(address(usd)), 0.05e18);
        market.borrow(address(usd), 100e6);
        assertEq(market.borrowRate(address(usd)), 0.55e18);
        market.borrow(address(usd), 100e6);
        assertEq(market.borrowRate(address(usd)), 1.05e18);
        vm.stopPrank();
        assertEq(market.utilization(address(usd)), 1e18);
    }

    // 価格0.85: 清算ライン680 < 借金700。carolが350を返してCOL 432.352941176470588235を受け取る。再び清算ライン386 > 借金350
    function test_F07_liquidateHalfWithBonus() public {
        _openPosition();
        _price(0.9e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 720e18, 700e18));
        market.liquidate(alice, address(usd), address(col), 350e6);
        _price(0.85e18);
        assertEq(market.liquidationLimit(alice), 680e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.AboveCloseFactor.selector, 350e6, 351e6));
        market.liquidate(alice, address(usd), address(col), 351e6);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 350e6);
        assertEq(market.debtOf(address(usd), alice), 350e6);
        assertEq(market.depositOf(address(col), carol), 432_352_941_176_470_588_235);
        assertEq(market.depositOf(address(col), alice), 567_647_058_823_529_411_765);
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 386e18, 350e18));
        market.liquidate(alice, address(usd), address(col), 175e6);
    }

    // 価格0.3: 担保の値300 < 借金700。借金全部まで(701はAboveCloseFactor(700, 701))、受け取る担保は預けた1000に、返す量は300 / 1.05
    function test_F07_underwaterFullLiquidation() public {
        _openPosition();
        _price(0.3e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.AboveCloseFactor.selector, 700e6, 701e6));
        market.liquidate(alice, address(usd), address(col), 701e6);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 700e6);
        assertEq(usd.balanceOf(carol), 10_000e6 - 285_714_286);
        assertEq(market.depositOf(address(col), carol), 1000e18);
        assertEq(market.depositOf(address(col), alice), 0);
        assertEq(market.debtOf(address(usd), alice), 414_285_714);
    }

    // 担保が残っていない借金414.285714を消すとbobの持ち分が1000から585.714286に。金庫のUSDと同じ
    function test_F08_writeOffSharesLoss() public {
        _openPosition();
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

    // 最後の12秒だけ16倍でも30分平均は1.1、上限825
    function test_F09_twapNotSpot() public {
        vm.prank(alice);
        market.deposit(address(col), 1000e18);
        vm.prank(alice);
        market.setCollateral(address(col), true);
        vm.warp(vm.getBlockTimestamp() + 30 minutes - 12);
        colFeed.setPrice(16e18);
        vm.warp(vm.getBlockTimestamp() + 12);
        assertEq(market.priceOf(address(col)), 1.1e18);
        (uint256 limit,) = market.accountHealth(alice);
        assertEq(limit, 825e18);
    }

    // 上場のルール: 設定キーだけ、一度だけ、比率80以下、ゼロアドレスでない、記録が30分より短い出どころは不可
    function test_F10_listAssetOnce() public {
        StdToken t = new StdToken("New", "NEW", 18);
        TwapFeed f = new TwapFeed(1e18);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.listAsset(address(t), f, 50, 1);
        vm.expectRevert(abi.encodeWithSelector(IMarket.AlreadyListed.selector, address(col)));
        market.listAsset(address(col), f, 50, 1);
        vm.expectRevert(abi.encodeWithSelector(IMarket.RatioAboveCap.selector, 81, 80));
        market.listAsset(address(t), f, 81, 1);
        vm.expectRevert(IMarket.ZeroAddress.selector);
        market.listAsset(address(t), TwapFeed(address(0)), 50, 1);
        uint256 t0 = vm.getBlockTimestamp();
        vm.expectRevert(abi.encodeWithSelector(TwapFeed.ShortHistory.selector, t0, t0 - 30 minutes));
        market.listAsset(address(t), f, 50, 1);
        vm.warp(t0 + 30 minutes);
        market.listAsset(address(t), f, 50, 1);
        assertEq(market.assetCount(), 3);
        (, uint8 d, uint8 ratio,, bool listed, uint256 cap) = market.assetConfig(address(t));
        assertEq(d, 18);
        assertEq(ratio, 50);
        assertTrue(listed);
        assertEq(cap, 1);
    }
}
