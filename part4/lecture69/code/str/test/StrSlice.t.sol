// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {StrSlice} from "../src/StrSlice.sol";

contract StrSliceTest is Test {
    function test_head() public {
        StrSlice c = new StrSlice();
        string memory r = c.head(unicode"あい");
        console.log(r);
        console.logBytes(bytes(r));
    }
}
