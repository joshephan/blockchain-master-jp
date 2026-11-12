// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Order} from "../src/mod/Order.sol";

contract OrderTest is Test {
    function test_Run() public {
        Order o = new Order();
        o.run();
        assertEq(o.calls(), 1);
    }
}
