// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Ext {
    function sumCalldata(uint[] calldata xs) external pure returns (uint total) {
        for (uint i = 0; i < xs.length; i++) total += xs[i];
    }

    function sumMemory(uint[] memory xs) external pure returns (uint total) {
        for (uint i = 0; i < xs.length; i++) total += xs[i];
    }

    function sumPublic(uint[] calldata xs) public pure returns (uint total) {
        for (uint i = 0; i < xs.length; i++) total += xs[i];
    }
}
