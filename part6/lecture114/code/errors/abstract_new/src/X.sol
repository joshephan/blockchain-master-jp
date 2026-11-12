// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Base {
    address public immutable owner;
    constructor(address o) { owner = o; }
}

abstract contract C is Base {}

contract Maker {
    function make() external returns (address) {
        return address(new C());
    }
}
