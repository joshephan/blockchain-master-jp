// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, Vm} from "forge-std/Test.sol";
import {Outer, Fail, Note} from "../src/Ev.sol";
contract RecTest is Test {
    function test_outer() public {
        Outer o = new Outer();
        vm.recordLogs();
        o.go(3);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        emit log_named_uint("count", logs.length);
        for (uint i; i < logs.length; i++) emit log_named_bytes32("t0", logs[i].topics[0]);
    }
    function test_fail() public {
        Fail f = new Fail();
        vm.recordLogs();
        try f.tryIt(5) {} catch {}
        Vm.Log[] memory logs = vm.getRecordedLogs();
        emit log_named_uint("count", logs.length);
    }
    function test_expectEmit() public {
        Note n = new Note();
        vm.expectEmit(address(n));
        emit Note.Noted(address(this), 7);
        n.note(7);
    }
}
