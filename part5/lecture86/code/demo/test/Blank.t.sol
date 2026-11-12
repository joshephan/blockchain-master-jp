// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Blank} from "../src/Blank.sol";

contract BlankTest is Test {
    function test_run() public {
        Blank b = new Blank();
        uint256 a = b.run();
        console.log("a", a);
        uint256[] memory l = b.logged();
        console.log("log length", l.length);
        for (uint256 i; i < l.length; ++i) console.log(l[i]);
    }
}
