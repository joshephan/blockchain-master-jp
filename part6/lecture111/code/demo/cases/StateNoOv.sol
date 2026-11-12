// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P { function x() external view virtual returns (uint256) { return 1; } }
contract C is P { uint256 public x = 7; }
