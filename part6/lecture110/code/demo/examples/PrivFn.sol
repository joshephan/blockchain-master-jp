// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract P { function _h() private pure returns (uint256) { return 1; } }
contract C is P { function g() public pure returns (uint256) { return _h(); } }
