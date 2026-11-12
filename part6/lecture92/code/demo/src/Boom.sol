// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Boom {
    uint256 public x;

    constructor(bool fail) {
        require(!fail, "boom");
        x = 1;
    }
}
