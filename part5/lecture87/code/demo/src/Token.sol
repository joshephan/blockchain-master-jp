// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// デモ用の最小トークン (balanceOf、transferだけ)
contract Token {
    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = 1000;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}
