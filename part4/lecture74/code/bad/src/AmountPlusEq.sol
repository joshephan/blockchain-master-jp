// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

contract AmountPlusEq {
    Amount public totalDeposits;

    function f(uint256 amount) external {
        totalDeposits += Amount.wrap(amount);
    }
}
