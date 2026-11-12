// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library Percent { function part(uint256 amount, uint256 pct) internal pure returns (uint256) { return amount * pct / 100; } }
contract C { function fee(uint256 a) external pure returns (uint256) { function(uint256, uint256) internal pure returns (uint256) f = Percent.part; return f(a, 3); } }
