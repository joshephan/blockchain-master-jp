// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, Rate, Ratio} from "../src/Market.sol";

contract MarketTest is Test {
    Market market;

    function setUp() public {
        uint64 n = vm.getNonce(address(this));
        address predicted = vm.computeCreateAddress(address(this), n);
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        console.log("nonce before    ", n);
        console.log("predicted Market", predicted);
        console.log("actual Market   ", address(market));
        assertEq(address(market), predicted);
    }

    function test_setUp() public view {
        assertEq(market.admin(), address(this));
    }
}
