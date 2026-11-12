// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Book {
    mapping(address asset => mapping(address user => uint256 amount)) public deposits;

    function deposit(address asset, uint256 amount) external {
        deposits[asset][msg.sender] += amount;
    }

    function pairTotal(address asset, address a, address b) external view returns (uint256) {
        mapping(address => uint256) storage inner = deposits[asset];
        return inner[a] + inner[b];
    }
}
