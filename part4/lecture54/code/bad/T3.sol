// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract T3 {
    function next(address a) external pure returns (address) {
        return a + 1;
    }
}
