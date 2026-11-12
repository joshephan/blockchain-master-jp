// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Redecl {
    function f() external pure returns (uint256) {
        uint256 x = 1;
        uint256 x = 2;
        return x;
    }
}
