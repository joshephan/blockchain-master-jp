// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P { function f() public payable virtual {} }
contract C is P { function f() public override {} }
