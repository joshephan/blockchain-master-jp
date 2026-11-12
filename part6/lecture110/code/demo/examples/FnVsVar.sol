// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { uint256 public count; }
contract C is P { function count() public pure returns (uint256) { return 1; } }
