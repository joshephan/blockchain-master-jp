// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Count {
    function f() internal pure returns (uint256, uint256, uint256) {
        return (7, 8, 9);
    }

    function g() external pure returns (uint256) {
        (uint256 a, uint256 b) = f();
        return a + b;
    }
}
