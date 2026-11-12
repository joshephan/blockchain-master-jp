// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract NoLocation {
    function f() external pure returns (uint256) {
        uint256[3] a;
        return a[0];
    }
}
