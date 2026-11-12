// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
interface I { function f() external view returns (uint256); }
contract C is I { function f() external pure returns (uint256) { return 3; } }
