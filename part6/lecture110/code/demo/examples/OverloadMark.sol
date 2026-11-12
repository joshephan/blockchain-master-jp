// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { function f(uint256 a) public pure virtual returns (uint256) { return a; } }
contract C is P { function f(uint8 a) public pure override returns (uint256) { return a; } }
