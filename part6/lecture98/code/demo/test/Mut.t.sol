// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test} from "forge-std/Test.sol";
import {Counter, Caller, Self} from "../src/Mut.sol";

contract MutTest is Test {
    Counter c; Caller k; Self s;
    function setUp() public { c = new Counter(); k = new Caller(); s = new Self(); }
    function test_viaView() public { vm.expectRevert(); k.viaView(address(c)); }
    function test_viaCall() public { assertEq(k.viaCall(address(c)), 1); assertEq(c.n(), 1); }
    function test_readGet() public view { k.readGet(address(c)); }
    function test_viaThis() public view { assertEq(s.viaThis(), 1); }
}
