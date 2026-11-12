// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {Gov58, Box} from "../src/Gov58.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

// タイムロック: 最小待機、作業id、待機の変更、先行する作業、デプロイ管理者、取り消しのロール、実行アドレス
contract Timelock216Test is Test {
    TimelockController tl;
    Box box;
    address proposer = address(0x9909);
    address guardian = address(0x6A2D);
    address anyone = address(0xA11);
    bytes data42 = abi.encodeCall(Box.setValue, (42));

    function setUp() public {
        address[] memory p = new address[](1);
        p[0] = proposer;
        address[] memory e = new address[](1);
        e[0] = address(0); // 実行は誰でも
        tl = new TimelockController(2 days, p, e, address(0)); // デプロイ管理者なし
        box = new Box(address(tl));
    }

    function test_minDelayEnforced() public {
        vm.prank(proposer);
        vm.expectRevert(abi.encodeWithSelector(TimelockController.TimelockInsufficientDelay.selector, 1 days, 2 days));
        tl.schedule(address(box), 0, data42, bytes32(0), bytes32(0), 1 days);
    }

    function test_operationIdIsHash() public view {
        bytes32 id = tl.hashOperation(address(box), 0, data42, bytes32(0), bytes32(uint256(1)));
        assertEq(id, keccak256(abi.encode(address(box), uint256(0), data42, bytes32(0), bytes32(uint256(1)))));
    }

    function test_readyThenDoneOnce() public {
        bytes32 id = tl.hashOperation(address(box), 0, data42, bytes32(0), bytes32(0));
        vm.prank(proposer);
        tl.schedule(address(box), 0, data42, bytes32(0), bytes32(0), 2 days);
        assertEq(tl.getTimestamp(id), vm.getBlockTimestamp() + 2 days);
        assertTrue(tl.isOperationPending(id));
        assertFalse(tl.isOperationReady(id));
        vm.prank(anyone);
        vm.expectRevert(); // TimelockUnexpectedOperationState(id, Ready)
        tl.execute(address(box), 0, data42, bytes32(0), bytes32(0));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        assertTrue(tl.isOperationReady(id));
        vm.prank(anyone);
        tl.execute(address(box), 0, data42, bytes32(0), bytes32(0));
        assertEq(box.value(), 42);
        assertTrue(tl.isOperationDone(id));
        vm.prank(anyone);
        vm.expectRevert();
        tl.execute(address(box), 0, data42, bytes32(0), bytes32(0)); // 同じidは二回できない
    }

    function test_strangerCannotSchedule() public {
        bytes32 role = tl.PROPOSER_ROLE();
        vm.prank(anyone);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, anyone, role));
        tl.schedule(address(box), 0, data42, bytes32(0), bytes32(0), 2 days);
    }

    function test_updateDelayOnlySelf() public {
        vm.prank(proposer);
        vm.expectRevert(abi.encodeWithSelector(TimelockController.TimelockUnauthorizedCaller.selector, proposer));
        tl.updateDelay(0);
        bytes memory d = abi.encodeCall(TimelockController.updateDelay, (3 days));
        vm.prank(proposer);
        tl.schedule(address(tl), 0, d, bytes32(0), bytes32(0), 2 days);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        tl.execute(address(tl), 0, d, bytes32(0), bytes32(0));
        assertEq(tl.getMinDelay(), 3 days);
    }

    function test_predecessorOrder() public {
        bytes memory d7 = abi.encodeCall(Box.setValue, (7));
        bytes32 a = tl.hashOperation(address(box), 0, data42, bytes32(0), bytes32(0));
        vm.startPrank(proposer);
        tl.schedule(address(box), 0, data42, bytes32(0), bytes32(0), 2 days);
        tl.schedule(address(box), 0, d7, a, bytes32(0), 2 days); // 42のあとでだけ7
        vm.stopPrank();
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert(abi.encodeWithSelector(TimelockController.TimelockUnexecutedPredecessor.selector, a));
        tl.execute(address(box), 0, d7, a, bytes32(0));
        tl.execute(address(box), 0, data42, bytes32(0), bytes32(0));
        tl.execute(address(box), 0, d7, a, bytes32(0));
        assertEq(box.value(), 7);
    }

    function test_deployAdminSkipsDelay() public {
        // デプロイ管理者を残したタイムロック: そのアカウントが待機なしでロールを与える
        address[] memory none = new address[](0);
        address deployer = address(0xDE9);
        TimelockController t2 = new TimelockController(2 days, none, none, deployer);
        bytes32 adminRole = t2.DEFAULT_ADMIN_ROLE();
        assertTrue(t2.hasRole(adminRole, deployer));
        assertTrue(t2.hasRole(adminRole, address(t2)));
        bytes32 proposerRole = t2.PROPOSER_ROLE();
        vm.prank(deployer);
        t2.grantRole(proposerRole, deployer); // 待機なし
        assertTrue(t2.hasRole(proposerRole, deployer));
        vm.prank(deployer);
        t2.renounceRole(adminRole, deployer);
        vm.prank(deployer);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, deployer, adminRole)
        );
        t2.grantRole(proposerRole, address(0xBAD));
    }

    function test_noDeployAdmin() public view {
        assertFalse(tl.hasRole(tl.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(tl.hasRole(tl.DEFAULT_ADMIN_ROLE(), address(tl)));
        assertTrue(tl.hasRole(tl.CANCELLER_ROLE(), proposer)); // 提案者は取り消しのロールも受け取る
    }
}

// ガバナー + タイムロック: 実行アドレスはタイムロック、取り消しのロールを持つ別のアドレス
contract GovTimelock216Test is Test {
    GovToken token;
    TimelockController tl;
    Gov58 gov;
    Box box;
    address alice = address(0xA11CE);
    address guardian = address(0x6A2D);
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    bytes32 dh = keccak256(bytes("set value 42"));

    function setUp() public {
        token = new GovToken(1000);
        token.transfer(alice, 100);
        vm.prank(alice);
        token.delegate(alice);
        address[] memory none = new address[](0);
        tl = new TimelockController(2 days, none, none, address(this));
        gov = new Gov58(token, tl, 1, 50, 0, 4);
        tl.grantRole(tl.PROPOSER_ROLE(), address(gov));
        tl.grantRole(tl.CANCELLER_ROLE(), address(gov));
        tl.grantRole(tl.CANCELLER_ROLE(), guardian); // 取り消しだけをする別のアドレス
        tl.grantRole(tl.EXECUTOR_ROLE(), address(0));
        tl.renounceRole(tl.DEFAULT_ADMIN_ROLE(), address(this));
        vm.roll(10);
    }

    function _queued(address boxOwner) internal returns (uint256 id) {
        box = new Box(boxOwner);
        targets.push(address(box));
        values.push(0);
        calldatas.push(abi.encodeCall(Box.setValue, (42)));
        vm.prank(alice);
        id = gov.propose(targets, values, calldatas, "set value 42");
        vm.roll(12);
        vm.prank(alice);
        gov.castVote(id, 1);
        vm.roll(62);
        gov.queue(targets, values, calldatas, dh);
    }

    function test_executorIsTimelock() public {
        _queued(address(tl));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        gov.execute(targets, values, calldatas, dh);
        assertEq(box.value(), 42); // Boxが見たmsg.senderはタイムロック
    }

    function test_permissionOnGovernorFails() public {
        uint256 id = _queued(address(gov)); // 権限をガバナーに置いた箱
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert(Box.NotOwner.selector);
        gov.execute(targets, values, calldatas, dh);
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Queued));
    }

    function test_guardianCancelsQueued() public {
        uint256 id = _queued(address(tl));
        bytes32 opId = tl.hashOperationBatch(targets, values, calldatas, 0, bytes20(address(gov)) ^ dh);
        assertTrue(tl.isOperationPending(opId));
        vm.prank(guardian);
        tl.cancel(opId); // 可決した提案も止められる
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Canceled));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        gov.execute(targets, values, calldatas, dh);
        assertEq(box.value(), 0);
    }

    function test_guardianCannotSchedule() public {
        bytes32 role = tl.PROPOSER_ROLE();
        vm.prank(guardian);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, guardian, role));
        tl.schedule(address(0x1), 0, "", bytes32(0), bytes32(0), 2 days);
    }
}
