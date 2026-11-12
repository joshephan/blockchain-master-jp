// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract CallCast8 {
    function f(uint8 a) public pure returns (uint256) {
        return a;
    }

    function f(uint256 a) public pure returns (uint256) {
        return a + 1000;
    }

    function g() external pure returns (uint256) {
        return f(uint8(1));
    }
}
