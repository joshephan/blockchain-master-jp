// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { function f() public pure virtual returns (uint256) { return 1; } }
contract C is P { function f() public pure returns (uint256) { return 2; } }
