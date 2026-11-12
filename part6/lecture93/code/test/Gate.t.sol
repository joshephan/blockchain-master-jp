// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Gate, Visitor} from "../src/Gate.sol";

contract GateTest is Test {
    function test_gate() public {
        Gate g = new Gate();
        Visitor v = new Visitor(g);
        console.log("in constructor ", v.seenInCtor());
        console.log("after deploy   ", v.askNow(g));
    }
}
