// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P4 {
    function f() external pure returns (uint256) { return address(this).balance; }
}
