// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
library AmountMath { function add(Amount a, Amount b) public pure returns (Amount) { return Amount.wrap(Amount.unwrap(a) + Amount.unwrap(b)); } }
using {AmountMath.add as +} for Amount global;
