// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract B4toU32 {
    function f(bytes4 a) external pure returns (uint32 b) {
        b = a;
    }
}
