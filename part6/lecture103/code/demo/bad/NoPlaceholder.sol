// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract NoPlaceholder {
    uint256 public x;
    modifier check() { require(msg.sender != address(0), "zero"); }
    function set(uint256 v) external check { x = v; }
}
