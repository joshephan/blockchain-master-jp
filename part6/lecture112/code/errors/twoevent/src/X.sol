// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract A { event E(uint256 v); }
contract B { event E(uint256 v); }
contract C is A, B { function g() public { emit E(1); } }
