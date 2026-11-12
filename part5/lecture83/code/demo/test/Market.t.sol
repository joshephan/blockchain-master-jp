// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio} from "../src/Market.sol";
import {MockToken, FalseToken} from "../src/Tokens.sol";

contract MarketTest is Test {
    Market m;
    MockToken tk;
    FalseToken ft;
    address alice = address(0xA11CE);

    function setUp() public {
        m = new Market();
        tk = new MockToken();
        ft = new FalseToken();
        m.addAsset(IERC20(address(tk)), Ratio.wrap(75));
        m.addAsset(IERC20(address(ft)), Ratio.wrap(75));
        tk.mint(alice, 1000);
        ft.mint(alice, 1000);
        vm.prank(alice);
        tk.approve(address(m), 500);
    }

    function test_deposit() public {
        vm.prank(alice, alice);
        m.deposit(address(tk), 500);
        console.log("lastSender", tk.lastSender());
        console.log("lastOrigin", tk.lastOrigin());
        console.log("market    ", address(m));
    }

    function test_withdraw() public {
        vm.prank(alice);
        m.deposit(address(tk), 500);
        vm.prank(alice);
        m.withdraw(address(tk), 200);
    }

    function test_depositFalseToken() public {
        vm.prank(alice);
        m.deposit(address(ft), 500);
    }

    function test_interfaceId() public pure {
        console.logBytes4(type(IERC20).interfaceId);
    }
}
