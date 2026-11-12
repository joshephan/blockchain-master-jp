// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract TupleVar {
    function f() internal pure returns (uint256, uint256) {
        return (1, 2);
    }

    function g() external pure returns (uint256) {
        uint256 t = f();
        return t;
    }
}
