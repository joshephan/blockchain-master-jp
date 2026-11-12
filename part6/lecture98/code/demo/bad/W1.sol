// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract W1 {
    uint256 public n;
    function f() external returns (uint256) { return n; }
    function g(uint256 a) external returns (uint256) { return a * 2; }
}
