// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract C { function f(uint256 x) external pure returns (uint256) { if (x > 0) unchecked { x--; } return x; } }
