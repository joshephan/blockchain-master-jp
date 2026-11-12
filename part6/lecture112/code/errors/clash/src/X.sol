// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract A { function burn(uint256) public pure returns (uint256) { return 1; } }
contract B { function collate_propagate_storage(bytes16) public pure returns (uint256) { return 2; } }
contract C is A, B { }
