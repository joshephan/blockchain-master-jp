// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Mix} from "../src/Mix.sol";

contract MixTest is Test {
    Mix m = new Mix();

    function test_show() public view {
        console.log("total     ", m.total(1e18, 1e6));
        console.log("mulRaw    ", m.mulRaw(1.5e18, 1.5e18));
        console.log("mulThenDiv", m.mulThenDiv(1.5e18, 1.5e18));
        console.log("divThenMul", m.divThenMul(1.5e18, 1.5e18));
        console.log("interest  ", m.mulThenDiv(999, 0.05e18));
    }
}
