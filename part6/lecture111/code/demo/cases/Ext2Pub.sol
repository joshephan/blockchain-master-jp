// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P { function f() external pure virtual returns (uint256) { return 1; } }
contract C is P { function f() public pure override returns (uint256) { return 2; } }
