// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract T4 {
    function f(uint256 n) external pure returns (address) {
        return address(n);
    }
}
