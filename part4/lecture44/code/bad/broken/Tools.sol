// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Good {
    function one() external pure returns (uint256) {
        return 1;
    }
}

contract Unused {
    function two() external pure returns (uint256) {
        return 2
    }
}
