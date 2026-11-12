// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Counter256 {
    uint256 public count;

    function increment() external {
        count += 1;
    }
}

contract Counter8 {
    uint8 public count;

    function increment() external {
        count += 1;
    }
}
