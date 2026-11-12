// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract PayToAddr {
    function f(address payable a) external pure returns (address b) {
        b = a;
    }
}
