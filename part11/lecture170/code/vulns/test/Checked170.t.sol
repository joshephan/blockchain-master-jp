// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Rejecter} from "../src/Payout170.sol";
import {IgnorerChecked} from "../src/Checked170.sol";

contract Checked170Test is Test {
    function test_checkedCallReverts() public {
        IgnorerChecked ig = new IgnorerChecked();
        vm.deal(address(ig), 1 ether);
        Rejecter r = new Rejecter();
        vm.expectRevert(abi.encodeWithSelector(IgnorerChecked.SendFailed.selector, address(r)));
        ig.pay(address(r), 1 ether);
        assertFalse(ig.done());
        assertEq(address(ig).balance, 1 ether);
        assertEq(address(r).balance, 0);
    }
}
