// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {StateMachineReturn} from "../src/StateMachineReturn.sol";

contract Return152Test is Test {
    function test_returnStillTransitions() public {
        StateMachineReturn m = new StateMachineReturn();
        vm.warp(block.timestamp + 13 days);
        m.g();
        assertEq(uint8(m.stage()), 3);
    }
}
