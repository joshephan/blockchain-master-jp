// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P3 {
    uint256 public n;
    function g() internal view returns (uint256) { return n; }
    function f() external pure returns (uint256) { return g(); }
}
