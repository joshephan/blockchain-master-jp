// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract VoterTypeOnly {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }
}
