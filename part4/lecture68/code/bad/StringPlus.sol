// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StringConcatPlus {
    function f(string memory a, string memory b) external pure returns (string memory) {
        return a + b;
    }
}
