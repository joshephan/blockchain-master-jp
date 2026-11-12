// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Loop139} from "../src/Loop139.sol";

contract Loop139Test is Test {
    function test_sum() public {
        Loop139 l = new Loop139();
        l.sum(1);
        uint256 g0 = gasleft();
        uint256 s = l.sum(100);
        uint256 used = g0 - gasleft();
        g0 = gasleft();
        l.sum(0);
        uint256 used0 = g0 - gasleft();
        console.log("sum(100)", s);
        console.log("gas sum(100)", used);
        console.log("gas sum(0)", used0);
    }
}
