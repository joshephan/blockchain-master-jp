// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第151講: 権限の一覧をテストで。状態を変える関数五つを管理者でないアカウントで呼び、管理者専用の二つだけがNotAdminか、
// tx.originが管理者でもmsg.senderが違えば止まるかを確認
contract AccessTest is Test {
    MockToken token;
    MockToken other;
    Market market;
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockToken();
        other = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(bob, 100);
    }

    function test_permissionTable() public {
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.addAsset(IERC20(address(other)), Ratio.wrap(50));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.setStatus(IMarket.MarketStatus.Frozen);
        market.deposit(address(token), 100);
        market.withdraw(address(token), 40);
        market.withdrawAll(address(token));
        vm.stopPrank();

        market.addAsset(IERC20(address(other)), Ratio.wrap(50));
        market.setStatus(IMarket.MarketStatus.Frozen);
        assertEq(market.assetCount(), 2);
        assertEq(token.balanceOf(bob), 100);
    }

    function test_originIsNotChecked() public {
        vm.prank(bob, address(this));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.setStatus(IMarket.MarketStatus.Frozen);
        assertEq(uint8(market.status()), 0);
    }
}
