// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
interface I { function f() external; }
contract C { function g() public { new I(); } }
