// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Clear184, ClearOnly184} from "../src/Clear184.sol";

contract Clear184Test is Test {
    function test_deleteBothClears() public {
        Clear184 c = new Clear184();
        (uint256 sAfter, uint256 tAfter) = c.run();
        console.log("s after delete", sAfter);
        console.log("t after delete", tAfter);
        assertEq(tAfter, 0, "transient t");
        assertEq(c.s(), 0, "storage s");
    }

    function test_deleteStorageOnlyClears() public {
        ClearOnly184 c = new ClearOnly184();
        assertEq(c.run(), 0, "storage s");
    }
}
