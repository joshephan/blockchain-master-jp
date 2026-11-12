// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm, console} from "forge-std/Test.sol";
import {Ev141} from "../src/Ev141.sol";

contract Ev141Test is Test {
    Ev141 e;
    function setUp() public { e = new Ev141(); }

    function show() internal returns (Vm.Log memory l) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        l = logs[0];
        console.log("topics", l.topics.length, "data", l.data.length);
        for (uint256 i = 0; i < l.topics.length; i++) console.logBytes32(l.topics[i]);
        if (l.data.length > 0) console.logBytes(l.data);
    }
    function u(uint256 a) internal pure returns (uint256[] memory r) { r = new uint256[](1); r[0] = a; }
    function u(uint256 a, uint256 b) internal pure returns (uint256[] memory r) { r = new uint256[](2); r[0] = a; r[1] = b; }

    function test_arr() public {
        vm.recordLogs();
        e.arr(u(1, 2));
        Vm.Log memory l = show();
        assertEq(l.topics[1], keccak256(abi.encode(uint256(1), uint256(2))));
        console.logBytes32(keccak256(abi.encode(u(1, 2))));
    }
    function test_str() public {
        vm.recordLogs();
        e.str("hi");
        Vm.Log memory l = show();
        assertEq(l.topics[1], keccak256("hi"));
    }
    function test_st() public {
        vm.recordLogs();
        e.st(Ev141.S("hi", 7));
        Vm.Log memory l = show();
        assertEq(l.topics[1], keccak256(abi.encodePacked(bytes32("hi"), uint256(7))));
        console.logBytes32(keccak256(abi.encode(Ev141.S("hi", 7))));
    }
    function test_dd_same_topic() public {
        vm.recordLogs();
        e.dd(Ev141.D(u(1), u(2, 3)));
        bytes32 t1 = show().topics[1];
        vm.recordLogs();
        e.dd(Ev141.D(u(1, 2), u(3)));
        bytes32 t2 = show().topics[1];
        assertEq(t1, t2);
        assertEq(t1, keccak256(abi.encode(uint256(1), uint256(2), uint256(3))));
    }
    function test_neg() public {
        vm.recordLogs();
        e.neg();
        show();
    }
    function test_both() public {
        vm.recordLogs();
        e.both("hi");
        show();
    }
    function test_anon() public {
        vm.recordLogs();
        e.anon();
        show();
    }
}
