// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {StdToken} from "./StdToken.sol";

// 第155講: Marketが使う承認はdepositのtransferFrom(msg.sender, Market, amount)の一か所。
// 他人がdepositを呼んでも承認した人の承認は使われないか、使って残った承認がそのまま残るかを確認
contract AllowanceTest is Test {
    Market market;
    StdToken std;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        std = new StdToken("Std Token", "STD", 18, 1000);
        std.transfer(alice, 500);
        std.transfer(bob, 500);
        market.addAsset(IERC20(address(std)), Ratio.wrap(75));
    }

    function test_onlyCallerAllowanceUsed() public {
        vm.prank(alice);
        std.approve(address(market), 100);
        vm.prank(bob);
        vm.expectRevert(bytes("insufficient allowance"));
        market.deposit(address(std), 100);
        assertEq(std.allowance(alice, address(market)), 100);
        assertEq(std.balanceOf(alice), 500);
    }

    function test_leftoverAllowanceStays() public {
        vm.startPrank(alice);
        std.approve(address(market), 100);
        market.deposit(address(std), 30);
        market.withdrawAll(address(std));
        vm.stopPrank();
        assertEq(std.allowance(alice, address(market)), 70);
        (Amount d,,,) = market.positions(address(std), alice);
        assertEq(Amount.unwrap(d), 0);
    }
}
