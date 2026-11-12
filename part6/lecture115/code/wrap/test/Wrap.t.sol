// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

contract WrapTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function test_assign() public view {
        IMarket im = market;
        assertEq(im.assetCount(), 0);
    }

    function test_wrongAddress() public view {
        IMarket fake = IMarket(address(token));
        fake.status();
    }
}
