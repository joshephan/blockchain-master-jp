// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

contract OldAssert {
    uint256 public x;

    function asrt(uint256 v) external {
        x = v;
        assert(v != 0);
    }
}
