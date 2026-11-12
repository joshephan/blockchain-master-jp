// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24;
contract A { function f() public pure returns (uint) { return 1; } } contract B is A { function f() public pure returns (uint) { return 2; } }
