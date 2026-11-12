// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Calls} from "../src/Calls.sol";

contract CallsTest is Test {
    Calls c;

    function setUp() public {
        c = new Calls();
    }

    function test_internal() public view {
        assertEq(c.viaInternal(), address(this));
    }

    function test_public() public view {
        assertEq(c.viaPublic(), address(this));
    }

    function test_this() public view {
        assertEq(c.viaThis(), address(c));
    }

    function test_memInternal() public view {
        assertEq(c.memInternal(), 2);
    }

    function test_memThis() public view {
        assertEq(c.memThis(), 1);
    }
}
