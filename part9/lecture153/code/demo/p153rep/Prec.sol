// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Prec {
    function f(uint160 x) external pure returns (bool) {
        return x & 0 == 1;
    }

    function g(uint160 x) external pure returns (bool) {
        return x & (0 == 1);
    }
}
