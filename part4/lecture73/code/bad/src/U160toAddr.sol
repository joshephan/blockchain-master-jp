// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract U160toAddr {
    function f(uint160 a) external pure returns (address b) {
        b = a;
    }
}
