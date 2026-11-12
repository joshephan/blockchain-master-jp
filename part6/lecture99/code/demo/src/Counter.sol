// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Counter {
    uint256 public n;
    function bump() external returns (uint256) { n += 1; return n; }
    function get() external view returns (uint256) { return n; }
}
