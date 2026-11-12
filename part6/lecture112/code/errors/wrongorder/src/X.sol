// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Base { }
contract A is Base { }
contract C is A, Base { }
