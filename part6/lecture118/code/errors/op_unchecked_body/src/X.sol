// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
function sub(Amount a, Amount b) pure returns (Amount) { unchecked { return Amount.wrap(Amount.unwrap(a) - Amount.unwrap(b)); } }
using {sub as -} for Amount global;
contract C { function f(Amount a, Amount b) external pure returns (Amount) { return a - b; } }
