// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract PlusLhs {
    uint256 public totalDeposits;

    function f() external {
        totalDeposits + 1 = 5;
    }
}
