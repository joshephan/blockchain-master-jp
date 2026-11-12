// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Ballot} from "../src/Ballot.sol";

contract BallotTest is Test {
    Ballot b;
    address alice = makeAddr("alice");
    address mallory = makeAddr("mallory");

    function setUp() public {
        bytes32[] memory names = new bytes32[](2);
        names[0] = "coffee";
        names[1] = "tea";
        b = new Ballot(names);
    }

    function test_ChairGivesRight() public {
        b.giveRightToVote(alice);
        (uint weight,,,) = b.voters(alice);
        assertEq(weight, 1);
    }

    function test_RevertWhen_NotChair() public {
        vm.prank(mallory);
        vm.expectRevert(bytes("Only chairperson can give right to vote."));
        b.giveRightToVote(alice);
    }
}
