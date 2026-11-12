// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StringEqual {
    function f(string memory a, string memory b) external pure returns (bool) {
        return a == b;
    }
}
