// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Zero {
    uint256 public a = 7; // 欄0
    uint256 public b = 7; // 欄1

    function zero() external {
        a = 0;
    }

    function wipe() external {
        delete b;
    }
}
