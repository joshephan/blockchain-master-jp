// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract C { error Bad(uint256 v); function f(uint256 v) external pure { require(v > 0, Bad(v)); } }
