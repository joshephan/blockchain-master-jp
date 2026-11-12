// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Mix2 {
    function f() internal pure returns (uint256, uint256) {
        return (1, 2);
    }

    function g() external pure returns (uint256) {
        uint256 b;
        (uint256 a, b) = f();
        return a + b;
    }
}
