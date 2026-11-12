// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract M1 { uint256 immutable v; constructor() { v = 1; } function f() external { v = 2; } }
