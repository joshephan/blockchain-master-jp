// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, InsufficientDeposit} from "../src/Market.sol";
import {MockToken, FalseToken} from "../src/Tokens.sol";

contract MarketTest is Test {
    Market market;
    MockToken tk;
    FalseToken ft;
    address alice = address(0xA11CE);

    function setUp() public {
        market = new Market();
        tk = new MockToken(1000);
        ft = new FalseToken();
        market.addAsset(IERC20(address(tk)), Ratio.wrap(75));
        market.addAsset(IERC20(address(ft)), Ratio.wrap(75));
        tk.transfer(alice, 100);
        vm.prank(alice);
        tk.approve(address(market), 100);
        vm.prank(alice);
        market.deposit(address(tk), 100);
    }

    function test_withdrawTooMuch() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientDeposit.selector, 100, 150));
        market.withdraw(address(tk), 150);
    }

    function test_zeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(bytes("zero amount"));
        market.deposit(address(tk), 0);
    }

    function test_notAdmin() public {
        vm.prank(alice);
        vm.expectRevert(bytes("not admin"));
        market.addAsset(IERC20(address(0xBEEF)), Ratio.wrap(75));
    }

    function test_zeroAsset() public {
        vm.expectRevert(bytes("zero asset"));
        market.addAsset(IERC20(address(0)), Ratio.wrap(75));
    }

    function test_notListed() public {
        vm.prank(alice);
        vm.expectRevert(bytes("not listed"));
        market.deposit(address(0xBEEF), 10);
    }

    function test_falseToken() public {
        vm.prank(alice);
        vm.expectRevert(bytes("transferFrom failed"));
        market.deposit(address(ft), 10);
    }
}
