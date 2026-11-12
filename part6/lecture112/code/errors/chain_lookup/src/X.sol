// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Base { function f() public pure virtual returns (string memory) { return "Base"; } }
contract A is Base { function f() public pure virtual override returns (string memory) { return "A"; } }
contract C is Base, A { }
