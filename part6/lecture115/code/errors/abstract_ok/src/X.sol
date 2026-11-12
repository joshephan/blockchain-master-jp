// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
abstract contract A { uint256 public x; constructor() { x = 1; } function f() public virtual returns (uint256); function g() public view returns (uint256) { return x; } }
contract C is A { function f() public pure override returns (uint256) { return 2; } }
