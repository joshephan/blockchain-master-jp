// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {FeeSwitchToken, FalseToken} from "./helpers/OddTokens.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// エラーリストのテスト。Market ABIのエラー22(IMarket 21 + SafeERC20 1)ごとに、そのエラーでリバートする場所を一つ
// リバートデータ全体(セレクターと引数)を照合。エラーの数はDocsTestが成果物から数える
contract ErrorsTest is Base {
    function setUp() public {
        _deploy(0);
    }

    function test_err_NotAdmin() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.setSupplyCap(address(usd), 1);
    }

    function test_err_NotGuardian() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotGuardian.selector, bob));
        market.pause(address(usd), 1);
    }

    function test_err_ZeroAddress() public {
        vm.expectRevert(IMarket.ZeroAddress.selector);
        new Market(address(this), address(0), 0);
        vm.expectRevert(IMarket.ZeroAddress.selector);
        market.setGuardian(address(0));
        vm.expectRevert(IMarket.ZeroAddress.selector);
        market.listAsset(address(new StdToken("T", "T", 18)), TwapFeed(address(0)), 50, 1);
    }

    function test_err_NotListed() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotListed.selector, address(0xBEEF)));
        market.deposit(address(0xBEEF), 1);
    }

    function test_err_AlreadyListed() public {
        vm.expectRevert(abi.encodeWithSelector(IMarket.AlreadyListed.selector, address(usd)));
        market.listAsset(address(usd), usdFeed, 80, 1);
    }

    function test_err_TooManyAssets() public {
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        for (uint256 i = 0; i < 18; i++) {
            market.listAsset(address(new StdToken("T", "T", 18)), f, 50, type(uint256).max);
        }
        address t = address(new StdToken("T", "T", 18));
        vm.expectRevert(abi.encodeWithSelector(IMarket.TooManyAssets.selector, 20));
        market.listAsset(t, f, 50, type(uint256).max);
    }

    function test_err_RatioAboveCap() public {
        StdToken t = new StdToken("T", "T", 18);
        vm.expectRevert(abi.encodeWithSelector(IMarket.RatioAboveCap.selector, 81, 80));
        market.listAsset(address(t), usdFeed, 81, 1);
    }

    // 金額0は五つの関数すべてで同じエラー
    function test_err_ZeroAmount() public {
        _openPosition();
        vm.startPrank(alice);
        vm.expectRevert(IMarket.ZeroAmount.selector);
        market.deposit(address(usd), 0);
        vm.expectRevert(IMarket.ZeroAmount.selector);
        market.withdraw(address(col), 0);
        vm.expectRevert(IMarket.ZeroAmount.selector);
        market.borrow(address(usd), 0);
        vm.expectRevert(IMarket.ZeroAmount.selector);
        market.repay(address(usd), 0);
        vm.expectRevert(IMarket.ZeroAmount.selector);
        market.liquidate(bob, address(usd), address(col), 0);
        vm.stopPrank();
    }

    function test_err_ZeroShares() public {
        _deploy(0.05e18);
        _openPosition();
        vm.warp(vm.getBlockTimestamp() + 30 days);
        vm.prank(dave);
        vm.expectRevert(IMarket.ZeroShares.selector);
        market.deposit(address(usd), 1);
    }

    function test_err_ActionPaused() public {
        market.pause(address(usd), 2);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.ActionPaused.selector, address(usd), 2));
        market.borrow(address(usd), 1);
    }

    // 預け入れの上限1000: 600預けたあと401 → SupplyCapExceeded(1000, 1001)、400はできる
    function test_err_SupplyCapExceeded() public {
        market.setSupplyCap(address(usd), 1000e6);
        vm.prank(bob);
        market.deposit(address(usd), 600e6);
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IMarket.SupplyCapExceeded.selector, 1000e6, 1001e6));
        market.deposit(address(usd), 401e6);
        vm.prank(dave);
        market.deposit(address(usd), 400e6);
        assertEq(market.totalDeposits(address(usd)), 1000e6);
    }

    function test_err_InsufficientDeposit() public {
        vm.prank(bob);
        market.deposit(address(usd), 100e6);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientDeposit.selector, 100e6, 101e6));
        market.withdraw(address(usd), 101e6);
    }

    // 借り入れ側の現金の確認: 預けた1000から700借りたあとdaveが301
    function test_err_InsufficientLiquidity() public {
        _openPosition();
        vm.startPrank(dave);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientLiquidity.selector, 300e6, 301e6));
        market.borrow(address(usd), 301e6);
        vm.stopPrank();
    }

    function test_err_InsufficientCollateral() public {
        _openPosition();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 750e18, 751e18));
        market.borrow(address(usd), 51e6);
    }

    function test_err_NoDebt() public {
        _openPosition();
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NoDebt.selector, address(usd)));
        market.repay(address(usd), 1e6);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NoDebt.selector, address(usd)));
        market.writeOffBadDebt(bob, address(usd));
    }

    function test_err_NotLiquidatable() public {
        _openPosition();
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 800e18, 700e18));
        market.liquidate(alice, address(usd), address(col), 1e6);
    }

    // 担保としてオンにしていない資産は清算で持っていけない
    function test_err_NotCollateral() public {
        _openPosition();
        vm.prank(alice);
        market.deposit(address(usd), 100e6);
        _price(0.85e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotCollateral.selector, address(usd)));
        market.liquidate(alice, address(usd), address(usd), 1e6);
    }

    function test_err_AboveCloseFactor() public {
        _openPosition();
        _price(0.85e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.AboveCloseFactor.selector, 350e6, 351e6));
        market.liquidate(alice, address(usd), address(col), 351e6);
    }

    function test_err_HasCollateral() public {
        _openPosition();
        vm.expectRevert(abi.encodeWithSelector(IMarket.HasCollateral.selector, 1000e18));
        market.writeOffBadDebt(alice, address(usd));
    }

    // 消す借金が預け入れの合計以上: 預けた1000を全部借りたアカウントの担保の値が0(平均価格0)
    // 清算で担保を空にすると借金が預け入れの合計より小さくなってこの行に届かない。届く道は価格0だけ(自己監査の候補)
    function test_err_LossExceedsDeposits() public {
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.startPrank(alice);
        market.deposit(address(col), 2000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 1000e6);
        vm.stopPrank();
        _price(0);
        // 30分のあいだ借りた比率100%(年100%)で利息が付いて借金1,000.057078、預け入れの合計は切り捨てなので1,000.057077
        uint256 loss = market.debtOf(address(usd), alice);
        assertEq(loss, 1_000_057_078);
        vm.expectRevert(abi.encodeWithSelector(IMarket.LossExceedsDeposits.selector, loss, loss - 1));
        market.writeOffBadDebt(alice, address(usd));
    }

    function test_err_AmountMismatch() public {
        FeeSwitchToken t = new FeeSwitchToken();
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        market.listAsset(address(t), f, 50, type(uint256).max);
        t.mint(bob, 100e18);
        t.setFee(100);
        vm.startPrank(bob);
        t.approve(address(market), type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(IMarket.AmountMismatch.selector, 100e18, 99e18));
        market.deposit(address(t), 100e18);
        vm.stopPrank();
    }

    function test_err_SafeERC20FailedOperation() public {
        FalseToken z = new FalseToken();
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        market.listAsset(address(z), f, 50, type(uint256).max);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(z)));
        market.deposit(address(z), 1e18);
    }
}
