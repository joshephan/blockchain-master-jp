// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract A { error E(uint256 v); }
contract B { error E(uint256 v); }
contract C is A, B { }
