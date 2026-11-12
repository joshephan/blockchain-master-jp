// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
abstract contract A { function f() public virtual returns (uint256); }
contract C is A { function f() public override returns (uint256) { return super.f(); } }
