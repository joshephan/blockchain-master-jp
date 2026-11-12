// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract BadShift {
    uint256 public x = 1 << 256;
}
