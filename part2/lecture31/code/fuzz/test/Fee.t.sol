// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Fee} from "../src/Fee.sol";

contract FeeTest is Test {
    Fee public f;

    function setUp() public {
        f = new Fee();
    }

    function test_Fee() public view {
        assertEq(f.fee(10000), 30);
    }

    function testFuzz_FeeNotAboveAmount(uint256 amount) public view {
        assertLe(f.fee(amount), amount);
    }

    function testFuzz_FeeNotAboveAmountBounded(uint256 amount) public view {
        amount = bound(amount, 0, 1e30);
        assertLe(f.fee(amount), amount);
    }

    function testFuzz_FeeNotZero(uint256 amount) public view {
        vm.assume(amount != 0);
        amount = bound(amount, 1, 1e30);
        assertGt(f.fee(amount), 0);
    }
}
