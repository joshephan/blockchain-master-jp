// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract DeleteMap {
    mapping(address => uint256) deposits;

    function reset() external {
        delete deposits;
    }
}
