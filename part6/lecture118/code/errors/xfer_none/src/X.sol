// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract C { function f(address a) external { a.transfer(5); } }
