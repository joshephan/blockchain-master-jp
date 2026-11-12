// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library PercentPub { function part(uint256 amount, uint256 pct) public pure returns (uint256) { return amount * pct / 100; } }
contract C { using PercentPub for uint256; function fee(uint256 a) external pure returns (uint256) { return a.part(3); } }
