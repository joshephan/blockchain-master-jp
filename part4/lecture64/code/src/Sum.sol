// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SumMemory {
    function sum(uint256[] memory xs) external pure returns (uint256 total) {
        for (uint256 i = 0; i < xs.length; i++) {
            total += xs[i];
        }
    }
}

contract SumCalldata {
    function sum(uint256[] calldata xs) external pure returns (uint256 total) {
        for (uint256 i = 0; i < xs.length; i++) {
            total += xs[i];
        }
    }
}
