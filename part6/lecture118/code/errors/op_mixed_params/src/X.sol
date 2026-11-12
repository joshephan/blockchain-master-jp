// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
function add(Amount a, uint256 b) pure returns (Amount) { return Amount.wrap(Amount.unwrap(a) + b); }
using {add as +} for Amount global;
