// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library L { function f() internal view returns (address) { return address(this); } }
contract C { function g() external view returns (address) { return L.f(); } }
