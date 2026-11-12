// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TwoAtOnce {
    function f(int8 x) external pure returns (uint256) {
        return uint256(x);
    }
}
