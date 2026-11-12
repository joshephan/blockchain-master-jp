// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Amount is uint256;
function shl(Amount a, Amount b) pure returns (Amount) { return a; }
using {shl as <<} for Amount global;
