// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library L { uint256 internal constant YEAR = 365 days; uint256 public constant DAY = 1 days; function f() internal pure returns (uint256) { return YEAR; } }
contract C { function g() external pure returns (uint256) { return L.f(); } }
