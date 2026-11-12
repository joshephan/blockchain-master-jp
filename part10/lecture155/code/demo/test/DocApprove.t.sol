// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DocToken} from "../src/DocToken.sol";

contract DocApproveTest is Test {
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    // 0でない上限の上に新しい値を書くと巻き戻す
    function test_docRejectsDirectChange() public {
        DocToken t = new DocToken(1000);
        t.transfer(alice, 1000);
        vm.startPrank(alice);
        t.approve(bob, 100);
        vm.expectRevert(bytes(""));
        t.approve(bob, 50);
        vm.stopPrank();
    }

    // bobが先に100を使い切ると上限が0になり、aliceのapprove(bob, 50)が通って、bobの合計は150
    function test_docRaceStill150() public {
        DocToken t = new DocToken(1000);
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(bob, 100);
        vm.prank(bob);
        t.transferFrom(alice, bob, 100);
        vm.prank(alice);
        t.approve(bob, 50);
        vm.prank(bob);
        t.transferFrom(alice, bob, 50);
        assertEq(t.balanceOf(bob), 150);
    }
}
