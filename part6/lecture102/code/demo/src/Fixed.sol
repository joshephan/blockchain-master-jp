// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Plain {
    uint256 public fee = 30;
}

contract Const {
    uint256 public constant FEE = 30;
}

contract Immut {
    uint256 public immutable fee;

    constructor(uint256 fee_) {
        fee = fee_;
    }
}
