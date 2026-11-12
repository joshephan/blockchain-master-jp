// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Notation} from "../src/Notation.sol";
import {SameOne} from "../src/SameOne.sol";

contract NotationTest is Test {
    function test_Notation() public {
        Notation n = new Notation();
        console.log(n.oneEther());
        console.log(n.twentyFive());
        console.log(n.million());
        console.logInt(n.minusOne());
        console.log(n.top());
        console.log(n.ff());
        console.log(n.ff2());
        console.logBytes2(n.pair());
        console.log(n.fee());
    }

    function test_SameOne() public {
        SameOne s = new SameOne();
        console.log(s.a());
        console.log(s.b());
        console.logInt(s.c());
        console.logBytes1(s.d());
        console.log(s.max8());
    }
}
