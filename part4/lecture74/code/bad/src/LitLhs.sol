// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract LitLhs {
    function f(uint256 x) external pure {
        1 = x;
    }
}
