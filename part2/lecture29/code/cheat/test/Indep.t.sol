// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

contract IndepTest is Test {
    function test_RollThenWarp() public {
        console.log(block.number, block.timestamp);
        vm.roll(block.number + 7200);
        console.log(block.number, block.timestamp);
        vm.warp(block.timestamp + 1 days);
        console.log(block.number, block.timestamp);
    }
}
