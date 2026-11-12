// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract C { uint transient x; function f() external { x = 1; } }
