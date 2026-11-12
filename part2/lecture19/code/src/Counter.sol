// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

contract Counter {
    uint256 public x;

    function dec() public {
        x = x - 1;
    }
}
