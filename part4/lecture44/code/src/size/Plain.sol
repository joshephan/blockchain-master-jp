// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Plain {
    uint256 public count;

    function poke() external {
        count += 1;
    }
}
