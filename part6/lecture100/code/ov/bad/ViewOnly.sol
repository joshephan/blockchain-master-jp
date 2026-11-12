// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ViewOnly {
    uint256 n;

    function f(uint256 a) external view returns (uint256) {
        return a + n;
    }

    function f(uint256 a) external returns (uint256) {
        n = a;
        return a;
    }
}
