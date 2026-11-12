// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";

contract AdminTest is Test {
    Market m;

    function setUp() public {
        m = new Market();
    }

    function test_admin() public view {
        console.log("this          ", address(this));
        console.log("market.admin()", m.admin());
    }
}
