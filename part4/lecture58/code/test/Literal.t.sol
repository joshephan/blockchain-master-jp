// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {AddHundred} from "../src/AddHundred.sol";
import {Rational} from "../src/Rational.sol";

contract LiteralTest is Test {
    AddHundred h = new AddHundred();
    Rational r = new Rational();

    function test_AddHundred155() public view {
        console.log(h.addHundred(155));
    }

    function test_AddHundred200() public view {
        console.log(h.addHundred(200));
    }

    function test_AddHundredWide200() public view {
        console.log(h.addHundredWide(200));
    }

    function test_Rational() public view {
        console.log(r.huge());
        console.log(r.half());
        console.log(r.divVar(5));
    }
}
