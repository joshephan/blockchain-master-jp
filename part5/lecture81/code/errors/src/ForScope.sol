// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ForScope {
    function last(uint256 n) external pure returns (uint256) {
        for (uint256 i = 0; i < n; i++) {
        }
        return i;
    }
}
