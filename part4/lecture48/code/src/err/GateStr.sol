// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract GateStr {
    uint256 public openAt;
    uint256 public opened;

    constructor(uint256 time) {
        openAt = time;
    }

    function open() external {
        require(block.timestamp > openAt, "Too early to open.");
        opened += 1;
    }
}
