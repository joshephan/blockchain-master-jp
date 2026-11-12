// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
function lt(Amount a, Amount b) pure returns (Amount) { return a; }
using {lt as <} for Amount global;
