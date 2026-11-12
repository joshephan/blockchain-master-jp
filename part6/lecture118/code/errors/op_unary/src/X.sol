// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
function neg(Amount a) pure returns (Amount) { return a; }
using {neg as -} for Amount global;
contract C { function f(Amount a) external pure returns (Amount) { return -a; } }
