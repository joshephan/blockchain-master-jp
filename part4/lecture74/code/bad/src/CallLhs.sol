// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract CallLhs {
    uint256 public totalDeposits;

    function getTotal() public view returns (uint256) {
        return totalDeposits;
    }

    function f() external {
        getTotal() = 1;
    }
}
