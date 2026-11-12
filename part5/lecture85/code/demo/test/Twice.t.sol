// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Twice} from "../src/Twice.sol";

contract TwiceTest is Test {
    function test_tens() public {
        Twice t = new Twice();
        t.tens();
        assertEq(t.x(), 21);
    }
}
