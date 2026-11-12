// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Source, Reader} from "../src/Three.sol";

contract ThreeTest is Test {
    Reader r;

    function setUp() public {
        r = new Reader(new Source());
    }

    function test_takeAll() public {
        assertEq(r.takeAll(), 24);
    }

    function test_takeOne() public {
        assertEq(r.takeOne(), 7);
    }
}
