// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
abstract contract A { function f() public pure returns (uint256) { return 1; } }
contract C { function g() public returns (address) { return address(new A()); } }
