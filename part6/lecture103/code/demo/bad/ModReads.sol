// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ModReads {
    modifier m() { require(v > 0); _; }
    function f(uint256 v) external m {}
}
