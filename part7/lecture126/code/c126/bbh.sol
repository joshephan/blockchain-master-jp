// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract C { function f() external view returns (bytes32) { return block.blockhash(1); } }
