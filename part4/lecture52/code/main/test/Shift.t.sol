// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Shift} from "../src/Shift.sol";

contract ShiftTest is Test {
    Shift s;

    function setUp() public {
        s = new Shift();
    }

    function test_SmallValues() public view {
        console.log("100 * 2  =", s.mul2(100));
        console.log("100 << 1 =", s.shl1(100));
    }

    function test_ShlUint8() public view {
        console.log("200 << 1 =", s.shl1(200));
    }

    function test_MulUint8() public view {
        console.log("200 * 2 =", s.mul2(200));
    }

    function test_SignedShr() public view {
        console.log("-7 / 2  =", s.sdiv2(-7));
        console.log("-7 >> 1 =", s.sshr1(-7));
        console.log("-8 / 2  =", s.sdiv2(-8));
        console.log("-8 >> 1 =", s.sshr1(-8));
        console.log("7 / 2   =", s.sdiv2(7));
        console.log("7 >> 1  =", s.sshr1(7));
    }

    function test_ShlFar() public view {
        console.log("1 << 255 =", s.shl(1, 255));
        console.log("1 << 256 =", s.shl(1, 256));
        console.log("1 << 1000 =", s.shl(1, 1000));
    }
}
