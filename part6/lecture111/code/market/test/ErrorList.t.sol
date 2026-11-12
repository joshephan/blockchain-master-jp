// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, MarketBase, IERC20, Ratio, Rate, InsufficientDeposit, ZeroAdmin, NotAdmin, MarketFrozen, NotActive, ZeroAsset,
    AlreadyListed, RatioAboveCap, NotListed, ZeroAmount, TransferFromFailed, TransferFailed} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 成功の印としてfalseを返すトークン。巻き戻さない
contract FalseToken {
    bool public fail;
    function setFail(bool f) external { fail = f; }
    function transferFrom(address, address, uint256) external view returns (bool) { return !fail; }
    function transfer(address, uint256) external view returns (bool) { return !fail; }
}

// 第109講: エラー一覧の行ごとに、そのエラーで巻き戻るケースを一つ。巻き戻りデータ全体を照合
contract ErrorListTest is Test {
    MockToken token;
    MockToken other;
    FalseToken ft;
    Market market;
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockToken();
        other = new MockToken();
        ft = new FalseToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.addAsset(IERC20(address(ft)), Ratio.wrap(50));
        market.deposit(address(token), 100);
    }

    function test_zeroAdmin() public {
        vm.expectRevert(ZeroAdmin.selector);
        new Market(address(0), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function test_notAdmin() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(NotAdmin.selector, bob));
        market.setStatus(MarketBase.MarketStatus.Frozen);
    }

    function test_marketFrozen() public {
        market.setStatus(MarketBase.MarketStatus.Frozen);
        vm.expectRevert(MarketFrozen.selector);
        market.withdraw(address(token), 1);
    }

    function test_notActive() public {
        market.setStatus(MarketBase.MarketStatus.DepositPaused);
        vm.expectRevert(abi.encodeWithSelector(NotActive.selector, uint8(1)));
        market.deposit(address(token), 1);
    }

    function test_zeroAsset() public {
        vm.expectRevert(ZeroAsset.selector);
        market.addAsset(IERC20(address(0)), Ratio.wrap(50));
    }

    function test_alreadyListed() public {
        vm.expectRevert(abi.encodeWithSelector(AlreadyListed.selector, address(token)));
        market.addAsset(IERC20(address(token)), Ratio.wrap(50));
    }

    function test_ratioAboveCap() public {
        vm.expectRevert(abi.encodeWithSelector(RatioAboveCap.selector, uint8(90), uint8(80)));
        market.addAsset(IERC20(address(other)), Ratio.wrap(90));
    }

    function test_notListed() public {
        vm.expectRevert(abi.encodeWithSelector(NotListed.selector, address(other)));
        market.deposit(address(other), 1);
    }

    function test_zeroAmount() public {
        vm.expectRevert(ZeroAmount.selector);
        market.deposit(address(token), 0);
        vm.expectRevert(ZeroAmount.selector);
        market.withdraw(address(token), 0);
    }

    function test_transferFromFailed() public {
        ft.setFail(true);
        vm.expectRevert(abi.encodeWithSelector(TransferFromFailed.selector, address(ft)));
        market.deposit(address(ft), 1);
    }

    function test_transferFailed() public {
        market.deposit(address(ft), 10);
        ft.setFail(true);
        vm.expectRevert(abi.encodeWithSelector(TransferFailed.selector, address(ft)));
        market.withdraw(address(ft), 10);
    }

    function test_insufficientDeposit() public {
        vm.expectRevert(abi.encodeWithSelector(InsufficientDeposit.selector, uint256(100), uint256(150)));
        market.withdraw(address(token), 150);
    }
}
