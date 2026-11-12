// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Ballot.sol";

contract MyVote is Ballot {
    constructor(bytes32[] memory names) Ballot(names) {}
}
