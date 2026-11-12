// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Imm {
    uint256 public immutable k;

    constructor(uint256 k_) {
        k = k_;
    }
}
