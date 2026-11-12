// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Gate} from "../src/Gate.sol";

contract GateTest is Test {
    Gate public g;

    function setUp() public {
        g = new Gate();
    }

    function testFuzz_Gate(uint256 x) public view {
        assertTrue(g.open(x));
    }
}
