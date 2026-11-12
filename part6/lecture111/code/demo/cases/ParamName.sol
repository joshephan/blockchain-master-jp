// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P { function f(uint256 amount) public pure virtual returns (uint256) { return amount; } }
contract C is P { function f(uint256 x) public pure override returns (uint256) { return x + 1; } }
