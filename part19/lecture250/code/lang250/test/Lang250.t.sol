// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Div250} from "../src/Div250.sol";
import {Lock250} from "../src/Lock250.sol";
import {ReentrancyGuard} from "@oz/utils/ReentrancyGuard.sol";

contract Lang250Test is Test {
    function test_negativeDivisionRoundsTowardZero() public {
        Div250 d = new Div250();
        assertEq(d.div(-1, 2), 0);
        assertEq(d.div(-7, 2), -3);
        assertEq(d.mod(-7, 2), -1);
    }

    function test_oneLockForBoth() public {
        Lock250 l = new Lock250();
        assertEq(uint256(vm.load(address(l), bytes32(uint256(0)))), 1); // ロックの欄(スロット0)の初期値1
        l.b();
        assertEq(l.count(), 10);
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        l.a();
        assertEq(l.count(), 10); // aがリバートしてcountはそのまま
        assertEq(uint256(vm.load(address(l), bytes32(uint256(0)))), 1);
    }
}
