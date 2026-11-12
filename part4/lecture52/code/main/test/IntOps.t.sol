// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {IntOps} from "../src/IntOps.sol";

contract IntOpsTest is Test {
    IntOps o;

    function setUp() public {
        o = new IntOps();
    }

    function test_DivByZero() public view {
        console.log("10 / 3 =", o.div(10, 3));
        console.log("10 % 3 =", o.mod(10, 3));
        console.log("10 / 0 =", o.div(10, 0));
    }

    function test_ModByZero() public view {
        console.log("10 % 0 =", o.mod(10, 0));
    }

    function test_Signed() public view {
        console.log("-7 / 2 =", o.sdiv(-7, 2));
        console.log("-7 % 3 =", o.smod(-7, 3));
        console.log("7 % -3 =", o.smod(7, -3));
        console.log("7 / -2 =", o.sdiv(7, -2));
        console.log("-3 % 2 =", o.smod(-3, 2));
    }

    function test_Int8MinDivMinusOne() public view {
        console.log("-127 / -1 =", o.div8(-127, -1));
        console.log("-128 / -1 =", o.div8(-128, -1));
    }

    function test_NegInt8Min() public view {
        console.log("-(-127) =", o.neg8(-127));
        console.log("-(-128) =", o.neg8(-128));
    }

    function test_Pow() public view {
        console.log("0 ** 0 =", o.pow(0, 0));
        console.log("2 ** 255 =", o.pow(2, 255));
        console.log("2 ** 256 =", o.pow(2, 256));
    }

    function test_PowTen() public view {
        console.log("10 ** 77 =", o.pow(10, 77));
        console.log("10 ** 78 =", o.pow(10, 78));
    }
}
