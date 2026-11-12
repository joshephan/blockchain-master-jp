// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract A { uint256 public x; }
contract B { uint256 public x; }
contract C is A, B { }
