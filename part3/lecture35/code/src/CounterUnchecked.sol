// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CounterUnchecked {
    uint256 public count;

    function increment() external {
        unchecked {
            count += 1;
        }
    }
}
