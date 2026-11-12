// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P { uint256 x; function f() public virtual returns (uint256) { x = 1; return x; } }
contract C is P { function f() public view override returns (uint256) { return x; } }
