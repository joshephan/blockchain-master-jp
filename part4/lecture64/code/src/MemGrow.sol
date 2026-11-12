// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MemGrow {
    function make(uint256 n) external pure returns (uint256) {
        uint256[] memory a = new uint256[](n);
        return a.length;
    }
}
