// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library Pay { function transfer(address self, address to, uint256 amt) internal pure returns (uint256) { return uint160(self) + uint160(to) + amt; } }
contract C { using Pay for address; function f(address a, address to) external pure returns (uint256) { return a.transfer(to, 5); } }
