// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MarkMemoryView {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    mapping(address => Voter) public voters;

    function giveRight(address who) external {
        voters[who].weight = 1;
    }

    function markVoted() external view {
        Voter memory v = voters[msg.sender];
        v.voted = true;
    }
}
