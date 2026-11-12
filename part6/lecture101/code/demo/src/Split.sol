// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Burner { function burn(uint256 v) external pure returns (uint256) { return v + 1; } }
contract Other { function collate_propagate_storage(bytes16 x) external pure returns (bytes16) { return x; } }
