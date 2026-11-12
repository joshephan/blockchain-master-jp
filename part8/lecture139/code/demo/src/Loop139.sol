// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Loop139 {
    function sum(uint256 n) external pure returns (uint256 s) {
        for (uint256 i = 0; i < n; ++i) {
            s += i;
        }
    }
}
