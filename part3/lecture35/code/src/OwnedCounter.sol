// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Owned} from "./Owned.sol";

contract OwnedCounter is Owned {
    uint256 public count;

    function increment() external {
        count += 1;
    }

    function decrement() external onlyOwner {
        count -= 1;
    }
}
