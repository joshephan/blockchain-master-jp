// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 利率の数字はある。その利息を払う行はない
contract Yield55Test is Test {
    Market market;
    MockToken token;
    address alice = address(0xA11CE);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(alice, 200);
    }

    function test_rateIsSet() public view {
        assertEq(Rate.unwrap(market.interestRate()), 5e16);
        assertEq(market.interestFor(100e18, market.interestRate(), 365 days), 5e18);
    }

    function test_yearLaterSameAmount() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(market.elapsedOf(address(token), alice), 365 days);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientDeposit.selector, 100, 101));
        market.withdraw(address(token), 101);
        vm.prank(alice);
        market.withdrawAll(address(token));
        assertEq(token.balanceOf(alice), 200);
    }

    // 返すと約束した持ち分の合計(totalDeposits)が金庫のトークンより大きくなる回があるか
    function test_owedNeverAboveCash() public {
        address bob = address(0xB0B);
        token.transfer(bob, 300);
        vm.prank(alice);
        market.deposit(address(token), 100);
        vm.prank(bob);
        market.deposit(address(token), 300);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), token.balanceOf(address(market)));
        vm.prank(bob);
        market.withdrawAll(address(token));
        vm.prank(alice);
        market.withdrawAll(address(token));
        assertEq(token.balanceOf(alice), 200);
        assertEq(token.balanceOf(bob), 300);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 0);
        assertEq(token.balanceOf(address(market)), 0);
    }

    function test_noBorrowSide() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        assertEq(Amount.unwrap(market.totalBorrows(address(token))), 0);
        (, Amount borrowed,,) = market.positions(address(token), alice);
        assertEq(Amount.unwrap(borrowed), 0);
    }
}
