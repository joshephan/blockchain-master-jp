// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {Gov, Box} from "../src/Gov.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

// 票を数える時点、定足数、実行待機の確認
contract Gov180Test is Test {
    GovToken token;
    TimelockController timelock;
    Gov gov;
    Box box;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address lender = address(0x1E4D);

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string constant DESC = "set value 42";

    function setUp() public {
        token = new GovToken(1000);
        token.transfer(alice, 100);
        token.transfer(lender, 900);
        address[] memory none = new address[](0);
        timelock = new TimelockController(2 days, none, none, address(this));
        gov = new Gov(token, timelock);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(gov));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        box = new Box(address(timelock));
        targets.push(address(box));
        values.push(0);
        calldatas.push(abi.encodeCall(Box.setValue, (42)));
        vm.roll(10);
    }

    function _propose() internal returns (uint256 id) {
        vm.prank(alice);
        id = gov.propose(targets, values, calldatas, DESC);
    }

    function test_balanceIsNotVotes() public {
        assertEq(token.balanceOf(alice), 100);
        assertEq(token.getVotes(alice), 0);
        vm.prank(alice);
        token.delegate(alice);
        assertEq(token.getVotes(alice), 100);
    }

    function test_votesCountedAtSnapshot() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(11);
        uint256 id = _propose();
        uint256 snap = gov.proposalSnapshot(id);
        assertEq(snap, 12);
        vm.roll(13);
        // 投票が開いたブロックで900を譲り受けて委任し、同じブロックで投票、投票後に返す
        vm.prank(lender);
        token.transfer(bob, 900);
        vm.prank(bob);
        token.delegate(bob);
        assertEq(token.getVotes(bob), 900);
        vm.prank(bob);
        uint256 w = gov.castVote(id, 1);
        assertEq(w, 0);
        vm.prank(bob);
        token.transfer(lender, 900);
        vm.prank(alice);
        assertEq(gov.castVote(id, 1), 100);
        (uint256 against, uint256 forVotes, uint256 abstain) = gov.proposalVotes(id);
        assertEq(forVotes, 100);
        assertEq(against + abstain, 0);
    }

    function test_voteBeforeStartReverts() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(11);
        uint256 id = _propose();
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Pending));
        vm.prank(alice);
        vm.expectRevert();
        gov.castVote(id, 1);
    }

    function test_quorumNotMet() public {
        // 委任した票10(全体1000の1%)、定足数4%(40)に届かない
        vm.prank(alice);
        token.transfer(bob, 90);
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(11);
        uint256 id = _propose();
        vm.roll(13);
        vm.prank(alice);
        gov.castVote(id, 1);
        vm.roll(13 + 51);
        assertEq(gov.quorum(12), 40);
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_timelockWaitsBeforeExecute() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(11);
        uint256 id = _propose();
        vm.roll(13);
        vm.prank(alice);
        gov.castVote(id, 1);
        vm.roll(13 + 51);
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Succeeded));
        bytes32 dh = keccak256(bytes(DESC));
        gov.queue(targets, values, calldatas, dh);
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Queued));
        vm.expectRevert();
        gov.execute(targets, values, calldatas, dh);
        assertEq(box.value(), 0);
        vm.warp(block.timestamp + 2 days);
        gov.execute(targets, values, calldatas, dh);
        assertEq(box.value(), 42);
        assertEq(uint8(gov.state(id)), uint8(IGovernor.ProposalState.Executed));
    }

    function test_boxOnlyTimelock() public {
        vm.expectRevert(Box.NotOwner.selector);
        box.setValue(7);
    }
}
