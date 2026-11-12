// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract NewAssert {
    uint256 public x;

    function asrt(uint256 v) external {
        x = v;
        assert(v != 0);
    }
}
