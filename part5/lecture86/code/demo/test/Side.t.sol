// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Side} from "../src/Side.sol";

contract SideTest is Test {
    function test_run() public {
        Side s = new Side();
        s.run();
        uint256[] memory l = s.logged();
        for (uint256 i; i < l.length; ++i) console.log(l[i]);
        console.log("slots(0)", s.slots(0));
    }
}
