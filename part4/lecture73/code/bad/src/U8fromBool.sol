// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract U8fromBool {
    function f(bool x) external pure returns (uint8) {
        return uint8(x);
    }
}
