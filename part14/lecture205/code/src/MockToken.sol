// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// デモ用トークン: 承認なしで移す、brokenなら巻き戻す
contract MockToken {
    mapping(address => uint256) public balanceOf;
    bool public broken;

    constructor() {
        balanceOf[msg.sender] = 1000;
    }

    function setBroken(bool b) external {
        broken = b;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(!broken, "token paused");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(!broken, "token paused");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}
