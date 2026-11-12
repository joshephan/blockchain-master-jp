// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {A, B, C} from "../src/Chain.sol";
import {Who} from "../src/Who.sol";

contract ChainTest is Test {
    C c;
    B b;
    A a;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        c = new C();
        b = new B(c);
        a = new A(b);
    }

    function test_throughAB() public {
        vm.prank(alice, alice);
        a.hit();
        console.log("C.msg.sender", c.lastSender());
        console.log("C.tx.origin ", c.lastOrigin());
    }

    function test_direct() public {
        vm.prank(alice, alice);
        c.hit();
        console.log("C.msg.sender", c.lastSender());
        console.log("C.tx.origin ", c.lastOrigin());
    }

    function test_prankTwo() public {
        vm.prank(bob, alice);
        c.hit();
        assertEq(c.lastSender(), bob);
        assertEq(c.lastOrigin(), alice);
    }

    function test_who() public {
        Who w = new Who();
        vm.prank(alice, alice);
        w.outer();
    }
}

contract PrankOneTest is Test {
    function test_prankOne() public {
        C c = new C();
        address bob = makeAddr("bob");
        vm.prank(bob);
        c.hit();
        console.log("C.msg.sender", c.lastSender());
        console.log("C.tx.origin ", c.lastOrigin());
    }
}
