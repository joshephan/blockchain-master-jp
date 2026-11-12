// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Small {
    uint8[10] public small;
    uint256 public tail;

    function set(uint256 i, uint8 v) external {
        small[i] = v;
    }
}
