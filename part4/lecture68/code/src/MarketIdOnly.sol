// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MarketIdOnly {
    bytes32 public marketId;

    constructor(string memory name) {
        marketId = keccak256(bytes(name));
    }
}
