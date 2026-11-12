// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract LendingDraft {
    bool public paused;

    function canDeposit(uint256 amount) public view returns (bool) {
        return !paused && amount > 0;
    }

    function canBorrow(uint256 amount) public view returns (bool) {
        return !paused && amount > 0;
    }
}
