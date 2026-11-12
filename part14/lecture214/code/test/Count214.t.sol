// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {Gov58, GovLate, Box} from "../src/Gov58.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

// 票を数えるブロック、定足数、賛成・反対・棄権の集計
contract Count214Test is Test {
    GovToken token;
    TimelockController timelock;
    Gov58 gov;
    Box box;
    address alice = address(0xA11CE); // 100
    address bob = address(0xB0B); // 100
    address carol = address(0xCA201); // 200
    address dave = address(0xDA7E); // 30
    address erin = address(0xE121); // 20
    address frank = address(0xF4A2); // 0
    // 残りの550はデプロイしたアカウントに残り、委任しない

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string constant DESC = "set value 42";

    function setUp() public {
        token = new GovToken(1000);
        token.transfer(alice, 100);
        token.transfer(bob, 100);
        token.transfer(carol, 200);
        token.transfer(dave, 30);
        token.transfer(erin, 20);
        address[] memory none = new address[](0);
        timelock = new TimelockController(2 days, none, none, address(0));
        gov = new Gov58(token, timelock, 1, 50, 0, 4);
        _self(alice);
        _self(bob);
        _self(carol);
        _self(dave);
        _self(erin);
        _self(frank);
        box = new Box(address(timelock));
        targets.push(address(box));
        values.push(0);
        calldatas.push(abi.encodeCall(Box.setValue, (42)));
        vm.roll(10);
    }

    function _self(address a) internal {
        vm.prank(a);
        token.delegate(a);
    }

    function _propose() internal returns (uint256 id) {
        vm.prank(alice);
        id = gov.propose(targets, values, calldatas, DESC);
    }

    function _vote(address a, uint8 s) internal returns (uint256) {
        vm.prank(a);
        return gov.castVote(_id(), s);
    }

    uint256 _pid;

    function _id() internal view returns (uint256) {
        return _pid;
    }

    function test_snapshotAndDeadline() public {
        _pid = _propose(); // ブロック10で提案
        assertEq(gov.proposalSnapshot(_pid), 11); // 10 + 投票の遅延1
        assertEq(gov.proposalDeadline(_pid), 61); // 11 + 期間50
        vm.roll(11);
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Pending));
        vm.roll(12);
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Active));
        vm.roll(61);
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Active));
        vm.roll(62);
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Defeated)); // 誰も投票しない
    }

    function test_quorumFromPastTotalSupply() public {
        _pid = _propose();
        vm.roll(12);
        // 委任した票は450だが定足数は全体1000の4%
        assertEq(gov.quorum(11), 40);
        assertEq(token.getPastTotalSupply(11), 1000);
    }

    function test_abstainCountsForQuorum() public {
        _pid = _propose();
        vm.roll(12);
        assertEq(_vote(dave, 1), 30); // 賛成30
        assertEq(_vote(erin, 2), 20); // 棄権20
        vm.roll(62);
        // 賛成30 + 棄権20 = 50 >= 40、賛成30 > 反対0
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Succeeded));
    }

    function test_forAloneBelowQuorum() public {
        _pid = _propose();
        vm.roll(12);
        _vote(dave, 1); // 賛成30だけ
        vm.roll(62);
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_tieIsDefeated() public {
        _pid = _propose();
        vm.roll(12);
        _vote(alice, 1); // 賛成100
        _vote(bob, 0); // 反対100
        vm.roll(62);
        (uint256 against, uint256 forVotes,) = gov.proposalVotes(_pid);
        assertEq(forVotes, 100);
        assertEq(against, 100);
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_doubleVoteReverts() public {
        _pid = _propose();
        vm.roll(12);
        _vote(alice, 1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorAlreadyCastVote.selector, alice));
        gov.castVote(_pid, 0);
    }

    function test_sameTokensVoteOnce() public {
        _pid = _propose();
        vm.roll(12);
        _vote(alice, 1); // 100
        vm.prank(alice);
        token.transfer(frank, 100); // 投票したトークンを、委任しておいたfrankへ
        assertEq(token.getVotes(frank), 100);
        assertEq(_vote(frank, 1), 0); // 票を数えるブロックでfrankは0
        (, uint256 forVotes,) = gov.proposalVotes(_pid);
        assertEq(forVotes, 100);
    }

    function test_votesArePublic() public {
        _pid = _propose();
        vm.roll(12);
        vm.expectEmit(true, false, false, true, address(gov));
        emit IGovernor.VoteCast(alice, _pid, 1, 100, "yes");
        vm.prank(alice);
        gov.castVoteWithReason(_pid, 1, "yes");
        assertTrue(gov.hasVoted(_pid, alice));
    }

    function test_hiddenVoteWithoutSalt() public pure {
        // 票の値だけをハッシュで隠すと: 候補が0・1・2の三つなので一つずつ入れてみれば分かる
        bytes32 c = keccak256(abi.encode(uint8(1)));
        uint8 found = 255;
        for (uint8 s = 0; s < 3; s++) {
            if (keccak256(abi.encode(s)) == c) found = s;
        }
        assertEq(found, 1);
        // 秘密の値を一緒に入れれば三つを入れてみても合わない
        bytes32 c2 = keccak256(abi.encode(uint8(1), bytes32(uint256(0x5EC2E7))));
        found = 255;
        for (uint8 s = 0; s < 3; s++) {
            if (keccak256(abi.encode(s)) == c2) found = s;
        }
        assertEq(found, 255);
    }

    function test_lateQuorumExtends() public {
        GovLate late = new GovLate(token, 10);
        vm.prank(alice);
        uint256 id = late.propose(targets, values, calldatas, DESC);
        assertEq(late.proposalDeadline(id), 61);
        vm.roll(61); // 最後のブロックで定足数を超える票
        vm.prank(carol);
        late.castVote(id, 1);
        assertEq(late.proposalDeadline(id), 71); // 61 + 10
        vm.roll(62);
        assertEq(uint8(late.state(id)), uint8(IGovernor.ProposalState.Active)); // 反対する時間ができる
        vm.prank(alice);
        late.castVote(id, 0);
        vm.prank(bob);
        late.castVote(id, 0);
        vm.roll(72);
        // 賛成200、反対200: 延びた期間に入った反対で同数になり否決
        assertEq(uint8(late.state(id)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_lastBlockWithoutExtension() public {
        _pid = _propose();
        vm.roll(61); // 最後のブロックで定足数を超える票、延ばすモジュールなし
        _vote(carol, 1);
        assertEq(gov.proposalDeadline(_pid), 61);
        vm.roll(62);
        assertEq(uint8(gov.state(_pid)), uint8(IGovernor.ProposalState.Succeeded)); // 反対するブロックがない
    }
}
