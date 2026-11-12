// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract A { function f() public pure virtual returns (string memory) { return "A"; } }
contract B { function f() public pure virtual returns (string memory) { return "B"; } }
contract C is A, B { function f() public pure override(B, A) returns (string memory) { return "C"; } }
