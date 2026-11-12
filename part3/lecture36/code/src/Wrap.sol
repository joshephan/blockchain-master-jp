// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Wrap {
    function addOne(uint8 x) external pure returns (uint8) {
        return x + 1;
    }

    function addOneUnchecked(uint8 x) external pure returns (uint8) {
        unchecked {
            return x + 1;
        }
    }
}
