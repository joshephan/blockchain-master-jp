// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount18 is uint256;
type Amount6 is uint256;
function add(Amount18 a, Amount18 b) pure returns (Amount18) { return Amount18.wrap(Amount18.unwrap(a) + Amount18.unwrap(b)); }
using {add as +} for Amount18 global;
contract C { function f(Amount18 a, Amount6 b) external pure returns (Amount18) { return a + b; } }
