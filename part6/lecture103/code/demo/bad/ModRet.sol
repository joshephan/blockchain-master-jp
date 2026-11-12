// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ModRet {
    uint256 public x;
    modifier stop() { return; _; }
    function f() external stop { x = 1; }
}
