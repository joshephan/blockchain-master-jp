// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    event Moved(address from, address to, uint256 amount);
    event Moved(address indexed from, address indexed to, uint256 amount);
}
