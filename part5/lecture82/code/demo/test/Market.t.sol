// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Amount} from "../src/Market.sol";

contract MarketTest is Test {
    Market m;
    address asset = address(0x1111);
    address alice = address(0xA11CE);

    function setUp() public {
        m = new Market();
        m.addAsset(IERC20(asset), Ratio.wrap(75));
    }

    function test_deposit() public {
        vm.prank(alice);
        m.deposit(asset, 500);
        vm.prank(alice);
        m.withdraw(asset, 200);
        (Amount d, , , ) = m.positions(asset, alice);
        assertEq(Amount.unwrap(d), 300);
    }
}
