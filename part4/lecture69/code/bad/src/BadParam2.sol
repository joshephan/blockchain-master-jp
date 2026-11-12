// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BadParam2 {
    function f(uint256[] calldata x) external pure {
        x[0] = 1;
    }
}
