// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Base, Child, Once, Count} from "../src/Mod.sol";

contract ModTest is Test {
    function test_child() public {
        Base b = new Base();
        Child c = new Child();
        vm.prank(address(0xBEEF));
        vm.expectRevert(bytes("not owner"));
        b.setX(1);
        vm.prank(address(0xBEEF));
        c.setX(1);
        assertEq(c.x(), 1);
    }

    function test_once() public {
        Once o = new Once();
        vm.expectRevert(bytes("not first"));
        o.bumpThenFirst();
        o.firstThenBump();
        assertEq(o.calls(), 1);
        vm.expectRevert(bytes("not first"));
        o.firstThenBump();
    }

    function test_maybe() public {
        Count c = new Count();
        assertEq(c.maybe(false), 0);
        assertEq(c.count(), 0);
        assertEq(c.maybe(true), 7);
        assertEq(c.count(), 1);
    }
}
