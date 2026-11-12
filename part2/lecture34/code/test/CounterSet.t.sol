// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CounterSetScript} from "../script/CounterSet.s.sol";

contract CounterSetScriptTest is Test {
    function test_Run() public {
        CounterSetScript s = new CounterSetScript();
        s.run();
        assertEq(s.counter().number(), 10);
        assertGt(address(s.counter()).code.length, 0);
    }
}
