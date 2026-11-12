// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Plain} from "../src/Plain.sol";

contract PlainTest is Test {
    Plain public p;

    function setUp() public {
        p = new Plain();
    }

    function testFuzz_Plain(uint256 x) public view {
        assertTrue(p.open(x));
    }
}
