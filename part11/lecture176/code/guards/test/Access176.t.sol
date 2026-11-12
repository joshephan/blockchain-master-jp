// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OwnedVault, RoleVault, HandoverVault} from "../src/Access176.sol";

contract Access176Test is Test {
    address owner = makeAddr("owner");
    address stranger = makeAddr("stranger");
    address pauser = makeAddr("pauser");
    address next = makeAddr("next");

    function test_ownerPasses() public {
        OwnedVault v = new OwnedVault(owner);
        vm.prank(owner);
        v.pause();
        assertTrue(v.paused());
    }

    function test_strangerRejected() public {
        OwnedVault v = new OwnedVault(owner);
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(OwnedVault.NotOwner.selector, stranger));
        v.pause();
    }

    // 直接呼んだ側はstranger、トランザクションを開いた側(tx.origin)はowner。msg.senderの確認が止める
    function test_relayedCallRejected() public {
        OwnedVault v = new OwnedVault(owner);
        vm.prank(stranger, owner);
        vm.expectRevert(abi.encodeWithSelector(OwnedVault.NotOwner.selector, stranger));
        v.pause();
        assertFalse(v.paused());
    }

    function test_roleMissingRejected() public {
        RoleVault v = new RoleVault(owner);
        bytes32 role = v.PAUSER_ROLE();
        vm.prank(owner); // 役割を与える人もPAUSER_ROLEがなければ止められない
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, owner, role));
        v.pause();
    }

    function test_roleGrantedPasses() public {
        RoleVault v = new RoleVault(owner);
        bytes32 role = v.PAUSER_ROLE();
        assertFalse(v.hasRole(role, pauser)); // 一度も与えていない役割はfalse
        vm.prank(owner);
        v.grantRole(role, pauser);
        vm.prank(pauser);
        v.pause();
        assertTrue(v.paused());
    }

    function test_twoStepHandover() public {
        HandoverVault v = new HandoverVault(owner);
        vm.prank(owner);
        v.transferOwnership(next);
        assertEq(v.owner(), owner); // まだ移っていない
        assertEq(v.pendingOwner(), next);
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        v.acceptOwnership();
        vm.prank(next);
        v.acceptOwnership();
        assertEq(v.owner(), next);
    }
}
