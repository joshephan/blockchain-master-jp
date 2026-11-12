// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

contract MarketTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    function test_depositWithdraw() public {
        market.deposit(address(token), 100);
        market.withdraw(address(token), 40);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 60);
    }
}
