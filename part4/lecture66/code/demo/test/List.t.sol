// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {List} from "../src/List.sol";

contract ListTest is Test {
    List l;

    function setUp() public {
        l = new List();
    }

    function test_popEmpty() public {
        l.removeLast();
    }

    function test_outOfRange() public {
        l.add(10);
        l.get(5);
    }

    function test_removeAt() public {
        l.add(10);
        l.add(20);
        l.add(30);
        l.add(40);
        l.removeAt(1);
        assertEq(l.len(), 3);
        assertEq(l.list(0), 10);
        assertEq(l.list(1), 40);
        assertEq(l.list(2), 30);
    }
}
