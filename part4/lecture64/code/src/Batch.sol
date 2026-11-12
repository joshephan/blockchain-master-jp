// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Batch {
    uint256 public total;

    function addAll(uint256[] calldata amounts) external {
        uint256 s = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            s += amounts[i];
        }
        total += s;
    }
}
