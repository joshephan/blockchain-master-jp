// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract CallOne {
    function f(uint8 a) public pure returns (uint256) {
        return a;
    }

    function f(uint256 a) public pure returns (uint256) {
        return a + 1000;
    }

    function g() external pure returns (uint256) {
        return f(1);
    }
}
