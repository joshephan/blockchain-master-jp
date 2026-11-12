// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract VoterWithVar {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    Voter public first;
    mapping(address => Voter) public voters;
}
