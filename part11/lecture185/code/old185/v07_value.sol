// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24;
contract C { function g() public payable {} } contract T { function f(C c) public { c.g.value(1)(); } }
