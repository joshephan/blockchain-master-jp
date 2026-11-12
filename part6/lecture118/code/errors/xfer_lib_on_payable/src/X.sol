// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library Pay { function transfer(address payable self, uint256 amt) internal pure returns (uint256) { return amt; } }
contract C { using Pay for address payable; function f(address payable a) external { a.transfer(5); } }
