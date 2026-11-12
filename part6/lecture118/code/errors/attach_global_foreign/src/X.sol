// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library Percent { function part(uint256 amount, uint256 pct) internal pure returns (uint256) { return amount * pct / 100; } }
using Percent for uint256 global;
