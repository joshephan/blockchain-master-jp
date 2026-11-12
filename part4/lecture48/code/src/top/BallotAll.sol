// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Voted, NotChairperson} from "./BallotDecls.sol";

contract BallotAll {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    address public chairperson;
    mapping(address => Voter) public voters;
    uint[] public voteCounts;

    modifier onlyChairperson() {
        if (msg.sender != chairperson) revert NotChairperson(msg.sender);
        _;
    }

    constructor(uint proposalCount) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        voteCounts = new uint[](proposalCount);
    }

    function giveRightToVote(address voter) external onlyChairperson {
        require(!voters[voter].voted, "The voter already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        voteCounts[proposal] += sender.weight;
        emit Voted(msg.sender, proposal);
    }
}
