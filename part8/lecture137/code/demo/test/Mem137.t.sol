// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";
import "../src/Mem137.sol";

contract Mem137Test is Test {
    Mem137 m;
    function setUp() public { m = new Mem137(); }
    function test_sizes() public view {
        (uint a, uint b, uint c, uint d, uint e, uint s, uint start) = m.sizes();
        console.log("start", start);
        console.log("uint8[4]", a); console.log("uint8[] new(4)", b); console.log("bytes1[] new(4)", c);
        console.log("bytes new(4)", d); console.log("string abc", e); console.log("struct S", s);
    }
    function test_nested() public view {
        (uint at, bytes32[] memory dump) = m.nested();
        console.log("x at", at);
        for (uint i = 0; i < dump.length; i++) { console.log(at + i * 32); console.logBytes32(dump[i]); }
    }
    function test_front() public view {
        bytes32[] memory d = m.front();
        for (uint i = 0; i < d.length; i++) console.logBytes32(d[i]);
    }
    function test_neverFreed() public view {
        (uint a, uint b, uint c, uint d) = m.neverFreed();
        console.log(a, b); console.log(c, d);
    }
    function test_afterEmit() public {
        (uint b, uint a, bytes32 w0, bytes32 w1) = m.afterEmit(7);
        console.log("fp before/after emit", b, a);
        console.logBytes32(w0); console.logBytes32(w1);
    }
    function test_expand() public view {
        uint[6] memory ns = [uint(32), 1024, 32 * 1024, 64 * 1024, 128 * 1024, 256 * 1024];
        for (uint i = 0; i < 6; i++) console.log(ns[i], m.expand(ns[i]));
    }
}
