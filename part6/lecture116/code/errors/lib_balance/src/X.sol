// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library L { function f() internal view returns (uint256) { return address(this).balance; } }
contract C { function g() external view returns (uint256) { return L.f(); } }
