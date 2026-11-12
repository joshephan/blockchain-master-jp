// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract V3 {
    uint256 public n;
    function g() internal { n += 1; }
    function f() external view { g(); }
}
