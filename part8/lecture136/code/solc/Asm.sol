// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract C { function f() external { assembly { tstore(0, 1) } } }
