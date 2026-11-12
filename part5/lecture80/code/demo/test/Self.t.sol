// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Self} from "../src/Self.sol";

contract SelfTest is Test {
    Self s;

    function setUp() public {
        s = new Self();
    }

    function test_internal() public view {
        address got = s.viaInternal();
        console.log("viaInternal", got);
    }

    function test_this() public view {
        address got = s.viaThis();
        console.log("viaThis    ", got);
        console.log("Self       ", address(s));
    }
}
