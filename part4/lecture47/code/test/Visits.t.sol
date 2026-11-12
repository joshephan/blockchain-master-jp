// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Visits} from "../src/Visits.sol";

contract VisitsTest is Test {
    Visits v;

    function setUp() public {
        v = new Visits();
    }

    function test_visit() public {
        v.visit();
        assertEq(v.visits(), 1);
    }
}
