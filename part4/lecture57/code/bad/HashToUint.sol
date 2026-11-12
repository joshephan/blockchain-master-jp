// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract HashToUint {
    function f() external pure returns (uint256) {
        uint256 h = keccak256("alice");
        return h;
    }
}
