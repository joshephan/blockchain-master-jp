// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Named {
    mapping(address user => uint256 amount) public deposits;
}
