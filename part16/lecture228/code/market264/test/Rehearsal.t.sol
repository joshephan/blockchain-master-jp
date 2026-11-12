// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {IMarket} from "../src/IMarket.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {MultiSigAdmin} from "./helpers/MultiSigAdmin.sol";

// 対応リハーサルで出たもの(incidents/rehearsal-01.md 7節)。攻撃ではない事故: 価格の出どころが0を書く、価格の出どころが止まる
// デプロイしたビルド(d551e83c)は変えない。テストは今のビルドの動作を固定する
contract RehearsalTest is Base {
    function setUp() public {
        _deploy(0);
        _openPosition(); // bob USD 1000、alice COL 1000を担保にUSD 700
        vm.startPrank(dave);
        market.deposit(address(col), 500e18);
        market.setCollateral(address(col), true); // 借金のない担保アカウント
        vm.stopPrank();
    }

    // R-01: 出どころが0を書くと30分平均が1分に1/30ずつ下がる。aliceの清算ライン800 × (1 - t/30)が借金700の下に行くまで3分45秒
    function test_R01_zeroPriceLiquidationWindow() public {
        colFeed.setPrice(0);
        vm.warp(vm.getBlockTimestamp() + 225); // 3分45秒
        assertEq(market.liquidationLimit(alice), 700e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 700e18, 700e18));
        market.liquidate(alice, address(usd), address(col), 1e6);
        vm.warp(vm.getBlockTimestamp() + 1);
        assertLt(market.liquidationLimit(alice), 700e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 100e6); // 3分46秒から清算できる
    }

    // R-01: 3分目に出どころが1.0に戻ると、平均は0.9までしか下がらずまた上がる。そのあいだaliceは清算ラインの内側
    function test_R01_fixWithinThreeMinutesNoLiquidation() public {
        colFeed.setPrice(0);
        vm.warp(vm.getBlockTimestamp() + 3 minutes);
        colFeed.setPrice(1e18);
        uint256 lowest = type(uint256).max;
        for (uint256 i = 0; i < 31; i++) {
            uint256 p = market.priceOf(address(col));
            if (p < lowest) lowest = p;
            assertGe(market.liquidationLimit(alice), 700e18);
            vm.warp(vm.getBlockTimestamp() + 1 minutes);
        }
        assertEq(lowest, 0.9e18);
    }

    // R-01: 0が30分ずっと続くと平均0 → ZeroPrice。清算・借金の消去も止まる(D-14)
    function test_R01_zeroForThirtyMinutesStops() public {
        colFeed.setPrice(0);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        vm.expectRevert(abi.encodeWithSelector(IMarket.ZeroPrice.selector, address(col)));
        market.priceOf(address(col));
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.ZeroPrice.selector, address(col)));
        market.liquidate(alice, address(usd), address(col), 100e6);
        vm.prank(alice);
        market.repay(address(usd), 100e6); // 返済はできる
    }

    // R-02: 出どころが止まると、担保としてオンにした資産の一部だけの引き出しは止まる。借金がなければ全部の引き出しと担保のオフはできる
    // (帳簿を直したあとに上限を見るので、全部引き出すとその資産の欄が0になり価格を読まない)
    function test_R02_feedStoppedDebtFreeExits() public {
        colFeed.stop();
        vm.startPrank(dave);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.withdraw(address(col), 100e18);
        market.withdrawAll(address(col));
        vm.stopPrank();
        assertEq(col.balanceOf(dave), 10_000e18);
        vm.startPrank(carol);
        market.deposit(address(col), 100e18);
        market.setCollateral(address(col), true);
        market.setCollateral(address(col), false); // オフにする側はその資産の価格を読まない
        market.withdraw(address(col), 40e18);
        vm.stopPrank();
    }

    // R-02: 借金があれば担保のオフが上限で止まる。借金を全部返せば(返済は価格を読まない)オフにして引き出す
    function test_R02_feedStoppedBorrowerRepaysThenExits() public {
        colFeed.stop();
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 0, 700e18));
        market.setCollateral(address(col), false);
        market.repay(address(usd), 700e6);
        market.setCollateral(address(col), false);
        market.withdraw(address(col), 1000e18);
        vm.stopPrank();
        assertEq(col.balanceOf(alice), 10_000e18);
    }

    // R-03: 事前に承認しておいた停止の提案は一度使えば終わり。次の事故のために新しい提案を承認し直しておく
    function test_R03_preApprovedPauseOnlyOnce() public {
        address[] memory owners = new address[](3);
        owners[0] = address(0xA);
        owners[1] = address(0xB);
        owners[2] = address(0xC);
        MultiSigAdmin council = new MultiSigAdmin(owners, 2);
        IMarket m = IMarket(address(market));
        // Baseは設定キー・停止キーともこのテストコントラクト。停止キーをマルチシグに
        market.setGuardian(address(council));
        vm.prank(address(0xA));
        uint256 id = council.propose(address(m), abi.encodeCall(IMarket.pause, (address(col), 3)));
        vm.prank(address(0xA));
        council.approve(id);
        vm.prank(address(0xB));
        council.approve(id);
        vm.prank(address(0xC));
        council.execute(id); // 署名者一人
        vm.prank(address(0xC));
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.AlreadyExecuted.selector, id));
        council.execute(id);
    }
}
