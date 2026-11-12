// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library Percent { function part(uint256 amount, uint256 pct) internal pure returns (uint256) { return amount * pct / 100; } }
contract C { using Percent for *; function fee(uint256 a) external pure returns (uint256) { return a.part(3); } }
