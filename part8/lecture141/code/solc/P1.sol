// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P1 { struct S { uint a; } function f(S memory s) external pure returns (bytes memory) { return abi.encodePacked(s); } }
