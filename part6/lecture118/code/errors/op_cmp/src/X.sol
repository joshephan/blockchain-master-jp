// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
function lt(Amount a, Amount b) pure returns (bool) { return Amount.unwrap(a) < Amount.unwrap(b); }
using {lt as <} for Amount global;
contract C { function f(Amount a, Amount b) external pure returns (bool) { return a < b; } function g(Amount a, Amount b) external pure returns (bool) { return a > b; } }
