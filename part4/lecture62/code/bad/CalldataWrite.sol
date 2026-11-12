// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract CalldataWrite {
    function f(uint[] calldata x) external {
        x[0] = 1;
    }
}
