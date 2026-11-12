// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract B4fromU64 {
    function f(uint64 x) external pure returns (bytes4) {
        return bytes4(x);
    }
}
