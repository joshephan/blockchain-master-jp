// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract BadDiv {
    function f() external pure returns (uint256) {
        uint x = 5 / 2;
        return x;
    }
}
