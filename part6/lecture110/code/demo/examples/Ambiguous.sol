// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { function f(uint256 a) public pure returns (uint256) { return a; } }
contract C is P { function f(uint8 a) public pure returns (uint256) { return a + 100; } function g() public pure returns (uint256) { return f(1); } }
