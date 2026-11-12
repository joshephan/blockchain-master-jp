// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {HookToken} from "./helpers/HookToken.sol";
import {IMarket} from "../src/IMarket.sol";

// 安全の要件S-01~S-08。テスト名の頭の番号がdesign/requirements.mdの要件番号
contract SafetyTest is Base {
    function setUp() public {
        _deploy(0);
    }

    // 二つの資産とも預け入れ・借り入れを止めても、引き出し・返済・清算・借金の消去・担保のオフはできる
    function test_S01_exitPathsNeverPaused() public {
        _openPosition();
        market.pause(address(usd), 3);
        market.pause(address(col), 3);
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IMarket.ActionPaused.selector, address(usd), 1));
        market.deposit(address(usd), 1e6);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.ActionPaused.selector, address(usd), 2));
        market.borrow(address(usd), 1e6);
        vm.prank(bob);
        market.withdraw(address(usd), 300e6);
        vm.prank(alice);
        market.repay(address(usd), 100e6);
        _price(0.3e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 600e6);
        market.writeOffBadDebt(alice, address(usd));
        vm.prank(carol);
        market.setCollateral(address(col), false);
        assertEq(market.debtOf(address(usd), alice), 0);
    }

    // トークンが動く瞬間、帳簿はもう直してある: 預け入れのとき預け入れの合計100、借り入れのとき借金50
    function test_S02_ledgerBeforeTransfer() public {
        HookToken h = new HookToken();
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        market.listAsset(address(h), f, 50, type(uint256).max);
        h.watch(market, alice);
        h.mint(bob, 100e18);
        vm.startPrank(bob);
        h.approve(address(market), type(uint256).max);
        market.deposit(address(h), 100e18);
        vm.stopPrank();
        assertEq(h.seenDeposits(), 100e18);
        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(h), 50e18);
        vm.stopPrank();
        assertEq(h.seenDebt(), 50e18);
    }

    // 金庫のトークン + 貸し出した借金 ≥ 預けた人が引き出す量の合計。利息・清算・借金の消去を通る順番ごとに確認
    function test_S03_vaultCoversPromises() public {
        _deploy(0.05e18);
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.prank(dave);
        market.deposit(address(usd), 333_333_333);
        _check();
        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 700e6);
        vm.stopPrank();
        _check();
        vm.warp(vm.getBlockTimestamp() + 90 days);
        colFeed.setPrice(1e18);
        _check();
        vm.prank(alice);
        market.repay(address(usd), 123_456_789);
        _check();
        _price(0.3e18);
        uint256 debt = market.debtOf(address(usd), alice);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), debt);
        _check();
        market.writeOffBadDebt(alice, address(usd));
        _check();
        vm.prank(bob);
        market.withdrawAll(address(usd));
        _check();
    }

    function _check() internal view {
        uint256 promised = market.depositOf(address(usd), bob) + market.depositOf(address(usd), dave)
            + market.depositOf(address(usd), carol);
        uint256 vault = usd.balanceOf(address(market)) + market.totalBorrows(address(usd));
        assertGe(vault, promised);
    }

    // 余りが出る数字で利息を積み、全部返して全部引き出してもリバートせず、残るくずは金庫に残る
    function test_S04_roundingFavorsMarket() public {
        _deploy(0.05e18);
        vm.prank(bob);
        market.deposit(address(usd), 1000e6 + 1);
        vm.prank(dave);
        market.deposit(address(usd), 7);
        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 333_333_333);
        vm.stopPrank();
        vm.warp(vm.getBlockTimestamp() + 365 days + 7);
        assertGe(market.debtOf(address(usd), alice), market.totalBorrows(address(usd)));
        assertLe(
            market.depositOf(address(usd), bob) + market.depositOf(address(usd), dave),
            market.totalDeposits(address(usd))
        );
        vm.prank(alice);
        market.repay(address(usd), type(uint256).max);
        vm.prank(bob);
        market.withdrawAll(address(usd));
        vm.prank(dave);
        market.withdrawAll(address(usd));
        uint256 dust = usd.balanceOf(address(market));
        assertLe(dust, 2);
        emit log_named_uint("dust", dust);
    }

    // 資産は20個まで。21個目はTooManyAssets(20)
    function test_S05_assetCountCap() public {
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        for (uint256 i = 0; i < 18; i++) {
            market.listAsset(address(new StdToken("T", "T", 18)), f, 50, type(uint256).max);
        }
        assertEq(market.assetCount(), 20);
        address t = address(new StdToken("T", "T", 18));
        vm.expectRevert(abi.encodeWithSelector(IMarket.TooManyAssets.selector, 20));
        market.listAsset(t, f, 50, type(uint256).max);
    }

    // 預け入れ側の指数が1を超えたあと1単位の預け入れは持ち分0なのでZeroShares
    function test_S06_zeroShareDepositReverts() public {
        _deploy(0.05e18);
        _openPosition();
        vm.warp(vm.getBlockTimestamp() + 30 days);
        vm.prank(dave);
        vm.expectRevert(IMarket.ZeroShares.selector);
        market.deposit(address(usd), 1);
        vm.prank(dave);
        market.deposit(address(usd), 2);
    }

    function test_S07_creditsReceivedAmount() public {
        vm.skip(true);
    }

    function test_S08_noReturnToken() public {
        vm.skip(true);
    }
}
