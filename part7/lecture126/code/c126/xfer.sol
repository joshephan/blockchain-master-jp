// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract C { function f(address payable a) external { a.transfer(1); bool ok = a.send(1); ok; } }
