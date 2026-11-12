// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Ov {
    function f(uint8 a) public pure returns (uint256) {
        return a;
    }

    function f(uint256 a) public pure returns (uint256) {
        return a + 1000;
    }

    function f(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function h() external pure returns (uint256) {
        return f(300);
    }
}
