// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

contract RangeTest is Test {
    function test_MinMax() public pure {
        console.log("uint8   min", type(uint8).min);
        console.log("uint8   max", type(uint8).max);
        console.log("uint16  max", type(uint16).max);
        console.log("uint32  max", type(uint32).max);
        console.log("uint64  max", type(uint64).max);
        console.log("uint128 max", type(uint128).max);
        console.log("uint256 max", type(uint256).max);
        console.log("int8    min", type(int8).min);
        console.log("int8    max", type(int8).max);
        console.log("int256  min", type(int256).min);
        console.log("int256  max", type(int256).max);
    }
}
