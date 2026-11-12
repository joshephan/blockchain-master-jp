// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract V1 {
    uint256 public n;
    function f() external view { n = 1; }
}
