// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Market {
    bytes32 public marketId;
    bool public paused;

    constructor(string memory name) {
        marketId = keccak256(bytes(name));
    }
}
