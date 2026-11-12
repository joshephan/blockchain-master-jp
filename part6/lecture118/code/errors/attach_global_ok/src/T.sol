// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
library L { function twice(Amount a) internal pure returns (Amount) { return Amount.wrap(Amount.unwrap(a) * 2); } }
using L for Amount global;
