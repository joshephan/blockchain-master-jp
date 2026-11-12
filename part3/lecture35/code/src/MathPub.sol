// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MathPub {
    function double(uint256 x) public pure returns (uint256) {
        return x * 2;
    }
}

contract CounterPub {
    uint256 public count = 1;

    function grow() external {
        count = MathPub.double(count);
    }
}
