// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { uint256 private secret = 42; }
contract C is P { function g() public view returns (uint256) { return secret; } }
