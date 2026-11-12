// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract A { modifier m() virtual { _; } }
contract B { modifier m() virtual { _; } }
contract C is A, B { function g() public m {} }
