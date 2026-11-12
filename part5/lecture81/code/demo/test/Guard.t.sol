// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Oracle, Guard} from "../src/Guard.sol";

contract GuardTest is Test {
    Guard g;

    function setUp() public {
        g = new Guard(new Oracle());
    }

    function test_false() public view {
        g.check(false);
    }

    function test_true() public view {
        g.check(true);
    }
}
