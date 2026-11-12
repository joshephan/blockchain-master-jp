// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { uint256 public count; }
contract S { uint256 public count; function g(uint256 count) public pure returns (uint256) { return count; } }
