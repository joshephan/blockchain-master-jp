// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Wrap} from "../src/Wrap.sol";

contract WrapTest is Test {
    Wrap w;

    function setUp() public {
        w = new Wrap();
    }

    function test_AddOne() public view {
        assertEq(w.addOne(255), 0);
    }

    function test_AddOneUnchecked() public view {
        assertEq(w.addOneUnchecked(255), 0);
    }
}
