// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library L { struct S { uint256 a; } enum E { A, B } event Ev(uint256 x); error Bad(uint256 x); modifier pos(uint256 x) { if (x == 0) revert Bad(x); _; } function f(uint256 x) internal pos(x) returns (uint256) { emit Ev(x); return x; } }
contract C { function g(uint256 x) external returns (uint256) { return L.f(x); } }
