// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24;
library L { function add(uint a, uint b) internal pure returns (uint) { return a + b; } }
contract A { using L for uint; }
contract B is A { function f(uint x) public pure returns (uint) { return x.add(1); } }
