// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Kinds {
    uint256 public constant LIMIT = 100;
    address public immutable owner;
    uint256 public total;

    constructor() {
        owner = msg.sender;
    }
}
