// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library Percent { function part(uint256 amount, uint256 pct) internal pure returns (uint256) { return amount * pct / 100; } }
contract C { function fee(uint256 a) external pure returns (uint256) { return Percent.part(a, 3); } }
contract D { function g(C c) external pure returns (bytes4) { return Percent.part.selector; } }
