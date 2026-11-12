// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
function add(uint256 a, uint256 b) pure returns (uint256) { return a - b; }
using {add as +} for uint256;
