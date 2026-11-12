// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Loop} from "../src/Loop.sol";
import {Sub} from "../src/Sub.sol";

contract GasTest is Test {
    Loop loop;
    Sub sub;

    function setUp() public {
        loop = new Loop();
        sub = new Sub();
    }

    function test_loopPlain100() public view {
        assertEq(loop.sumPlain(100), 4950);
    }

    function test_loopWrapped100() public view {
        assertEq(loop.sumWrapped(100), 4950);
    }

    function test_gapChecked() public view {
        assertEq(sub.gapChecked(10, 3), 7);
    }

    function test_gapUnchecked() public view {
        assertEq(sub.gapUnchecked(10, 3), 7);
    }

    function test_loopPlain1000() public view {
        assertEq(loop.sumPlain(1000), 499500);
    }

    function test_loopWrapped1000() public view {
        assertEq(loop.sumWrapped(1000), 499500);
    }

    function test_loopPlusEq100() public view {
        assertEq(loop.sumPlusEq(100), 4950);
    }

    function test_loopPlusEq1000() public view {
        assertEq(loop.sumPlusEq(1000), 499500);
    }
}
