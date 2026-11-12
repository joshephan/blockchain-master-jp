// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

contract VmAddrTest is Test {
    function test_VmAddress() public view {
        console.log(address(vm));
        console.log(address(uint160(uint256(keccak256("hevm cheat code")))));
        console.log(address(vm).code.length);
    }
}
