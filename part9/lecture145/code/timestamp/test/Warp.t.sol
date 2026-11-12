// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";
contract WarpTest is Test {
    function test_warpTwice() public {
        uint256 a = block.timestamp;
        vm.warp(block.timestamp + 1);
        uint256 b = block.timestamp;
        vm.warp(block.timestamp + 1);
        uint256 c = block.timestamp;
        console.log(a, b, c);
        console.log(vm.getBlockTimestamp());
    }
}
