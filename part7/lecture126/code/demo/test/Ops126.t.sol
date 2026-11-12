// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console2} from "forge-std/Test.sol";
import {Ops126} from "../src/Ops126.sol";

contract Ops126Test is Test {
    Ops126 o;
    function setUp() public { o = new Ops126(); }
    function test_print() public view {
        console2.log("bitEq(2)", o.bitEq(2));
        console2.log("bitEq(3)", o.bitEq(3));
        console2.log("negPow(3)", o.negPow(3));
        console2.log("powPow(2,3,2)", o.powPow(2, 3, 2));
        console2.log("shiftAdd(2)", o.shiftAdd(2));
        console2.log("mm(2**255,4,7)", o.mm(2**255, 4, 7));
        console2.log("interest(1000e18, 5e16, 1 days)", o.interest(1000e18, 5e16, 1 days));
        console2.log("interestSwapped", o.interestSwapped(1000e18, 5e16, 1 days));
    }
    function test_plainMulModPanics() public {
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        o.plainMulMod(2**255, 4, 7);
    }
    function test_addmodZero() public {
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x12));
        o.am(1, 2, 0);
    }
}
