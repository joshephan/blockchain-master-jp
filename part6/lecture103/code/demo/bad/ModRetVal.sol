// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ModRetVal {
    modifier m() { _; return 3; }
    function f() external m returns (uint256) { return 1; }
}
