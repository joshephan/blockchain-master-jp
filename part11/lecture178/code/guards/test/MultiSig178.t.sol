// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MultiSigAdmin} from "../src/MultiSigAdmin.sol";
import {OwnedVault} from "../src/Access176.sol";

contract MultiSig178Test is Test {
    address a = makeAddr("a");
    address b = makeAddr("b");
    address c = makeAddr("c");
    address d = makeAddr("d");
    address stranger = makeAddr("stranger");
    MultiSigAdmin ms;
    OwnedVault vault;

    function setUp() public {
        address[] memory o = new address[](3);
        o[0] = a;
        o[1] = b;
        o[2] = c;
        ms = new MultiSigAdmin(o, 2);
        vault = new OwnedVault(address(ms)); // 管理者の席にマルチシグのアドレス
    }

    function _proposePause() internal returns (uint256 id) {
        vm.prank(a);
        id = ms.propose(address(vault), abi.encodeCall(OwnedVault.pause, ()));
    }

    function test_oneApprovalNotEnough() public {
        uint256 id = _proposePause();
        vm.prank(a);
        ms.approve(id);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.BelowThreshold.selector, id, 1));
        ms.execute(id);
        assertFalse(vault.paused());
    }

    function test_twoApprovalsExecute() public {
        uint256 id = _proposePause();
        vm.prank(a);
        ms.approve(id);
        vm.prank(b);
        ms.approve(id);
        vm.prank(c);
        ms.execute(id);
        assertTrue(vault.paused());
    }

    function test_executeOnce() public {
        uint256 id = _proposePause();
        vm.prank(a);
        ms.approve(id);
        vm.prank(b);
        ms.approve(id);
        vm.prank(a);
        ms.execute(id);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.AlreadyExecuted.selector, id));
        ms.execute(id);
    }

    function test_sameOwnerTwiceRejected() public {
        uint256 id = _proposePause();
        vm.prank(a);
        ms.approve(id);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.AlreadyApproved.selector, id, a));
        ms.approve(id);
    }

    function test_strangerCannotApprove() public {
        uint256 id = _proposePause();
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.NotOwner.selector, stranger));
        ms.approve(id);
    }

    // 署名者一人が対象コントラクトを直接呼んでも管理者ではない
    function test_ownerAloneNotAdmin() public {
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(OwnedVault.NotOwner.selector, a));
        vault.pause();
    }

    function test_directReplaceRejected() public {
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.NotSelf.selector, a));
        ms.replaceOwner(c, d);
    }

    // 鍵一つ(c)を失くしても、残りの二人が承認して新しい鍵(d)に替える
    function test_replaceLostKey() public {
        vm.prank(a);
        uint256 id = ms.propose(address(ms), abi.encodeCall(MultiSigAdmin.replaceOwner, (c, d)));
        vm.prank(a);
        ms.approve(id);
        vm.prank(b);
        ms.approve(id);
        vm.prank(b);
        ms.execute(id);
        assertFalse(ms.isOwner(c));
        assertTrue(ms.isOwner(d));
        assertEq(ms.ownerCount(), 3);
    }

    function test_badThresholdRejected() public {
        address[] memory o = new address[](2);
        o[0] = a;
        o[1] = b;
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.BadThreshold.selector, 3, 2));
        new MultiSigAdmin(o, 3);
    }
}
