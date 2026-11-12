// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { uint256 private count; }
contract C is P { uint256 private count; }
