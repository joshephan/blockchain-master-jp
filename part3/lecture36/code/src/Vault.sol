// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vault {
    uint256 private secret;

    constructor(uint256 s) {
        secret = s;
    }
}
