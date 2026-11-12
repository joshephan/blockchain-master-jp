// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {B, Del, Twice, Active, Order, Clean, Big} from "../src/Diff133.sol";

contract Diff133Test is Test {
    function test_show() public {
        console.log("B.y", new B().y());
        Del d = new Del();
        d.fill();
        console.logBytes32(d.raw());
        d.clear();
        console.logBytes32(d.raw());
        console.log("Twice.f(0)", new Twice().f(0));
        console.log("Active.foo()", new Active().foo());
        Order o = new Order();
        console.log("preincr_u8(1)", o.preincr_u8(1));
        console.log("g(1, 2)", o.g(1, 2));
        (uint256 a, uint256 m) = o.m();
        console.log("addmod", a);
        console.log("mulmod", m);
        (uint r1, uint r2) = new Clean().f(1);
        console.logBytes32(bytes32(r1));
        console.logBytes32(bytes32(r2));
        Big b = new Big();
        uint g0 = gasleft();
        (bool ok, bytes memory ret) = address(b).call{gas: 1_000_000}(abi.encodeCall(Big.f, ()));
        console.log("Big ok", ok, g0 - gasleft());
        console.logBytes(ret);
    }
}
