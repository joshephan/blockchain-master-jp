// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lit {
    function f() external pure returns (uint256) {
        return type(uint256).max + 1;
    }
}
