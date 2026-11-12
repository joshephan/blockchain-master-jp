// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Count2 {
    function f() internal pure returns (uint256, uint256, uint256) {
        return (7, 8, 9);
    }

    function g() external pure returns (uint256 a) {
        (a, ) = f();
    }
}
