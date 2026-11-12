// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount, ZeroAmount} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第100講: 全部引き出すのはwithdrawAllという別の名前で
contract WithdrawAllTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    function test_withdrawAll() public {
        market.deposit(address(token), 100);
        market.withdrawAll(address(token));
        (Amount deposited, , , ) = market.positions(address(token), address(this));
        assertEq(Amount.unwrap(deposited), 0);
        assertEq(token.balanceOf(address(this)), 1000);
    }

    function test_withdrawAllEmptyReverts() public {
        vm.expectRevert(ZeroAmount.selector); // 第108講
        market.withdrawAll(address(token));
    }
}
