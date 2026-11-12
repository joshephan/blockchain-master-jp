// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract GateReq {
    error TooEarly(uint256 time);

    uint256 public openAt;
    uint256 public opened;

    constructor(uint256 time) {
        openAt = time;
    }

    function open() external {
        require(block.timestamp > openAt, TooEarly(openAt));
        opened += 1;
    }
}
