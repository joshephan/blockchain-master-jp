// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SimpleToken {
    uint8 public decimals;
    mapping(address => uint256) public balanceOf;

    constructor(uint8 d, uint256 initial) {
        decimals = d;
        balanceOf[msg.sender] = initial;
    }
}
