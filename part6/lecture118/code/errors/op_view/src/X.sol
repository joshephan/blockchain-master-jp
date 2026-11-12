// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
function add(Amount a, Amount b) view returns (Amount) { return Amount.wrap(Amount.unwrap(a) + Amount.unwrap(b) + block.number); }
using {add as +} for Amount global;
