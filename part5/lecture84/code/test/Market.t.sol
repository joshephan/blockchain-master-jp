// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

contract MarketTest is Test {
    Market market;
    MockToken token;

    function setUp() public {
        uint64 n = vm.getNonce(address(this));
        address predictedMarket = vm.computeCreateAddress(address(this), n);
        address predictedToken = vm.computeCreateAddress(address(this), n + 1);

        market = new Market();
        token = new MockToken();

        console.log("nonce before   ", n);
        console.log("predicted Market", predictedMarket);
        console.log("actual Market   ", address(market));
        console.log("predicted Token ", predictedToken);
        console.log("actual Token    ", address(token));
    }

    function test_setUp() public view {
        assertEq(market.admin(), address(this));
    }
}
