// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract U8toBool {
    function f(uint8 a) external pure returns (bool b) {
        b = a;
    }
}
