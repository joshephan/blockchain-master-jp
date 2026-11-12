// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {Gov58, Box} from "../src/Gov58.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// 提案id、提案のしきい値、提案者の表示、取り消し、まとめて実行、設定の変更、状態の流れ
contract Gov215Test is Test {
    GovToken token;
    TimelockController timelock;
    Gov58 gov;
    Box box;
    address alice = address(0xA11CE); // 100
    address bob = address(0xB0B); // 100
    address dave = address(0xDA7E); // 5

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string constant DESC = "set value 42";

    function setUp() public {
        token = new GovToken(1000);
        token.transfer(alice, 100);
        token.transfer(bob, 100);
        token.transfer(dave, 5);
        address[] memory none = new address[](0);
        timelock = new TimelockController(2 days, none, none, address(this));
        gov = new Gov58(token, timelock, 1, 50, 10, 4); // 提案のしきい値10票
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(gov));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(gov));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));
        box = new Box(address(timelock));
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(bob);
        token.delegate(bob);
        vm.prank(dave);
        token.delegate(dave);
        targets.push(address(box));
        values.push(0);
        calldatas.push(abi.encodeCall(Box.setValue, (42)));
        vm.roll(10);
    }

    function _pass(uint256 id) internal {
        vm.roll(vm.getBlockNumber() + 2);
        vm.prank(alice);
        gov.castVote(id, 1);
        vm.prank(bob);
        gov.castVote(id, 1);
        vm.roll(vm.getBlockNumber() + 50);
    }

    function test_proposalIdIsHash() public {
        uint256 expected = uint256(keccak256(abi.encode(targets, values, calldatas, keccak256(bytes(DESC)))));
        assertEq(gov.hashProposal(targets, values, calldatas, keccak256(bytes(DESC))), expected); // 上げる前に計算
        vm.prank(alice);
        uint256 id = gov.propose(targets, values, calldatas, DESC);
        assertEq(id, expected);
        emit log_named_bytes32("proposalId", bytes32(id));
        emit log_named_address("box", address(box));
    }

    function test_sameProposalTwiceReverts() public {
        vm.prank(alice);
        uint256 id = gov.propose(targets, values, calldatas, DESC);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorUnexpectedProposalState.selector, id, IGovernor.ProposalState.Pending, bytes32(0)
            )
        );
        gov.propose(targets, values, calldatas, DESC);
        vm.prank(bob);
        uint256 id2 = gov.propose(targets, values, calldatas, "set value 42 (again)");
        assertTrue(id2 != id);
    }

    function test_thresholdBlocksSmallProposer() public {
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorInsufficientProposerVotes.selector, dave, 5, 10));
        gov.propose(targets, values, calldatas, DESC);
    }

    function test_proposerSuffix() public {
        string memory d = string.concat(DESC, " #proposer=", Strings.toHexString(alice));
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorRestrictedProposer.selector, bob));
        gov.propose(targets, values, calldatas, d);
        vm.prank(alice);
        gov.propose(targets, values, calldatas, d);
    }

    function test_cancelOnlyPendingByProposer() public {
        vm.prank(alice);
        uint256 id = gov.propose(targets, values, calldatas, DESC);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorUnableToCancel.selector, id, bob));
        gov.cancel(targets, values, calldatas, keccak256(bytes(DESC)));
        vm.roll(12); // Active
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorUnableToCancel.selector, id, alice));
        gov.cancel(targets, values, calldatas, keccak256(bytes(DESC)));
    }

    function test_cancelWhilePending() public {
        vm.prank(alice);
        uint256 id = gov.propose(targets, values, calldatas, DESC);
        vm.prank(alice);
        gov.cancel(targets, values, calldatas, keccak256(bytes(DESC)));
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Canceled));
    }

    function test_batchIsAllOrNothing() public {
        Box other = new Box(address(0xD00D)); // タイムロックが直せない箱
        targets.push(address(other));
        values.push(0);
        calldatas.push(abi.encodeCall(Box.setValue, (7)));
        vm.prank(alice);
        uint256 id = gov.propose(targets, values, calldatas, "two calls");
        _pass(id);
        gov.queue(targets, values, calldatas, keccak256(bytes("two calls")));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert(Box.NotOwner.selector);
        gov.execute(targets, values, calldatas, keccak256(bytes("two calls")));
        assertEq(box.value(), 0); // 最初の呼び出しも一緒にリバート
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Queued));
    }

    function test_settingsOnlyByGovernance() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, alice));
        gov.setVotingPeriod(10);
        address[] memory t = new address[](1);
        uint256[] memory v = new uint256[](1);
        bytes[] memory c = new bytes[](1);
        t[0] = address(gov);
        c[0] = abi.encodeCall(GovernorSettings.setVotingPeriod, (10));
        vm.prank(alice);
        uint256 id = gov.propose(t, v, c, "period 10");
        _pass(id);
        gov.queue(t, v, c, keccak256(bytes("period 10")));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        gov.execute(t, v, c, keccak256(bytes("period 10")));
        assertEq(gov.votingPeriod(), 10);
    }

    function test_lifecycle() public {
        vm.prank(alice);
        uint256 id = gov.propose(targets, values, calldatas, DESC);
        assertEq(uint8(gov.state(id)), 0); // Pending
        vm.roll(12);
        assertEq(uint8(gov.state(id)), 1); // Active
        vm.prank(alice);
        gov.castVote(id, 1);
        vm.roll(62);
        assertEq(uint8(gov.state(id)), 4); // Succeeded
        gov.queue(targets, values, calldatas, keccak256(bytes(DESC)));
        assertEq(uint8(gov.state(id)), 5); // Queued
        assertEq(gov.proposalEta(id), vm.getBlockTimestamp() + 2 days);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.prank(dave); // 実行は誰でも送れる
        gov.execute(targets, values, calldatas, keccak256(bytes(DESC)));
        assertEq(uint8(gov.state(id)), 7); // Executed
        assertEq(box.value(), 42);
    }
}
