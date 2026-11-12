// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Cst { uint256 public constant K = 7; }
contract UseCst { function f() external pure returns (uint256) { return type(Cst).runtimeCode.length; } }
