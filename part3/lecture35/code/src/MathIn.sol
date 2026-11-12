// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MathIn {
    function double(uint256 x) internal pure returns (uint256) {
        return x * 2;
    }
}

contract CounterIn {
    uint256 public count = 1;

    function grow() external {
        count = MathIn.double(count);
    }
}
