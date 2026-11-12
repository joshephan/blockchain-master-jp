// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract VarLength {
    uint256 public n = 10;
    uint256[n] public slots;
}
