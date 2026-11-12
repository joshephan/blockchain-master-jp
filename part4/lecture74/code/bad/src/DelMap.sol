// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract DelMap {
    mapping(address => uint256) public deposits;

    function f() external {
        delete deposits;
    }
}
