// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test} from "forge-std/Test.sol";
import {Ops126} from "../src/Ops126.sol";
contract Show126Test is Test {
    Ops126 o;
    function setUp() public { o = new Ops126(); }
    function test_mm() public view { assertEq(o.mm(2**255, 4, 7), 4); }
    function test_plainMulMod() public view { o.plainMulMod(2**255, 4, 7); }
    function test_am0() public view { o.am(1, 2, 0); }
}
