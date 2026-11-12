// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Order, Count, After, Inner} from "../src/Mod.sol";

contract ModTest is Test {
    function test_order() public {
        Order o = new Order();
        o.run();
    }

    function test_orderSwapped() public {
        Order o = new Order();
        o.runSwapped();
    }

    function test_count() public {
        Count c = new Count();
        c.two();
        assertEq(c.count(), 2);
        c.three();
        assertEq(c.count(), 5);
        assertEq(c.maybe(false), 0);
        assertEq(c.count(), 5);
        assertEq(c.maybe(true), 7);
        assertEq(c.count(), 6);
    }

    function test_after() public {
        After a = new After();
        assertEq(a.early(true), 5);
        assertEq(a.post(), 1);
        assertEq(a.calls(), 0);
        assertEq(a.early(false), 9);
        assertEq(a.post(), 2);
        vm.expectRevert(bytes("body failed"));
        a.fail();
        assertEq(a.post(), 2);
    }

    function test_inner() public {
        Inner i = new Inner();
        assertEq(i.outer(3), 6);
        assertEq(i.checks(), 2);
        vm.expectRevert(bytes("zero value"));
        i.outer(0);
    }
}
