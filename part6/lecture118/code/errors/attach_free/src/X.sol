// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
function part(uint256 amount, uint256 pct) pure returns (uint256) { return amount * pct / 100; }
using {part} for uint256;
contract C { function fee(uint256 a) external pure returns (uint256) { return a.part(3); } }
