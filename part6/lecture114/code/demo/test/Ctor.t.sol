// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm} from "forge-std/Test.sol";
import {Top} from "../src/Ctor.sol";

contract CtorTest is Test {
    function test_order() public {
        vm.recordLogs();
        Top top = new Top(address(0xBEEF), 3);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            (string memory what, uint256 v) = abi.decode(logs[i].data, (string, uint256));
            emit log_named_uint(what, v);
        }
        assertEq(top.r(), 3);
    }
}
