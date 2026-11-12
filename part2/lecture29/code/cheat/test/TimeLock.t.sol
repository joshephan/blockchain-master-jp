// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract TimeLockTest is Test {
    TimeLock lock;
    address alice = address(0xA11CE);

    function setUp() public {
        lock = new TimeLock();
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        lock.deposit{value: 1 ether}();
    }

    function test_TooEarly() public {
        vm.warp(block.timestamp + 1 days - 1);
        vm.expectRevert();
        vm.prank(alice);
        lock.withdraw();
    }

    function test_AfterOneDay() public {
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        lock.withdraw();
        assertEq(alice.balance, 1 ether);
    }

    function test_Roll() public {
        uint256 before = block.number;
        vm.roll(before + 7200);
        assertEq(block.number, before + 7200);
    }
}
