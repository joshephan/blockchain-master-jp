// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract TernLhs {
    uint256 public a;
    uint256 public b;

    function f(bool c) external {
        (c ? a : b) = 1;
    }
}
