// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Amount} from "../src/Market.sol";
import {TryMarket} from "../src/TryMarket.sol";
import {MockToken} from "../src/MockToken.sol";

contract DepositTest is Test {
    MockToken token;
    Market market;
    TryMarket tryMarket;

    function setUp() public {
        token = new MockToken();
        market = new Market();
        tryMarket = new TryMarket();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        tryMarket.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.setBroken(true);
    }

    function test_market_brokenToken() public {
        vm.expectRevert("token paused");
        market.deposit(address(token), 100);
        console.log("Market    totalDeposits", Amount.unwrap(market.totalDeposits(address(token))));
    }

    function test_tryMarket_brokenToken() public {
        tryMarket.depositTry(address(token), 100);
        console.log("TryMarket totalDeposits", Amount.unwrap(tryMarket.totalDeposits(address(token))));
        console.log("TryMarket token balance", token.balanceOf(address(tryMarket)));
    }

    function test_tryMarket_revertWithReason() public {
        vm.expectRevert("token failed: token paused");
        tryMarket.depositTryRevert(address(token), 100);
    }
}
