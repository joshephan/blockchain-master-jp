// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Locals {
    function f() public pure {
        bytes32 h = "abc";
        uint[] a;
    }
}
