// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P2 { function f(uint[][] memory a) external pure returns (bytes memory) { return abi.encodePacked(a); } }
