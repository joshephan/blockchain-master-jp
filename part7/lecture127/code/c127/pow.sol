// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

contract Pow {
    function dec(uint256 x) external pure returns (uint256) { return x - 1; }
    function negPow(int256 x) external pure returns (int256) { return -x ** 2; }
    function powPow(uint256 a, uint256 b, uint256 c) external pure returns (uint256) { return a ** b ** c; }
}
