// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
interface IBase { function f() external view returns (uint256); }
interface I is IBase { enum S { A, B } struct P { uint256 a; } event E(S s); error Bad(S s); function g(S s) external; }
