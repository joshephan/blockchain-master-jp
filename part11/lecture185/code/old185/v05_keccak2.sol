// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24;
contract T { function f(uint a, uint b) public pure returns (bytes32) { return keccak256(a, b); } }
