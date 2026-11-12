// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Owned} from "../src/Owned.sol";

contract StartPrankTest is Test {
    Owned owned;
    address alice = address(0xA11CE);

    function setUp() public {
        vm.prank(alice);
        owned = new Owned();
    }

    function test_PrankOnlyOnce() public {
        vm.prank(alice);
        owned.setFee(10);
        owned.setFee(20);
    }

    function test_StartPrank() public {
        vm.startPrank(alice);
        owned.setFee(10);
        owned.setFee(20);
        vm.stopPrank();
        assertEq(owned.fee(), 20);
    }

    function test_LoadOwner() public view {
        console.logBytes32(vm.load(address(owned), bytes32(uint256(0))));
    }
}
