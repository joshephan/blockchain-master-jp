// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Base {
    address public immutable owner;
    constructor(address o) { owner = o; }
}

contract C is Base(address(0xA11CE)) {
    constructor(address o) Base(o) {}
}
