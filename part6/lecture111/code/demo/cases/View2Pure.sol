// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P { uint256 x; function f() public view virtual returns (uint256) { return x; } }
contract C is P { function f() public pure override returns (uint256) { return 2; } }
