// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract ProbeTest is Test {
    function test_Probe() public {
        console.logBytes(address(vm).code);
        console.log(address(this));
        console.log(block.timestamp);
        console.log(block.number);
    }

    function test_TooEarlyNoExpect() public {
        TimeLock lock = new TimeLock();
        lock.deposit{value: 1 ether}();
        vm.warp(block.timestamp + 1 days - 1);
        lock.withdraw();
    }
}
