// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Imm { uint256 public immutable k; constructor(uint256 k_) { k = k_; } }
contract UseRt { function f() external pure returns (uint256) { return type(Imm).runtimeCode.length; } }
