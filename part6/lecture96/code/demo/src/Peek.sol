// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Peek {
    uint256[] public list;

    constructor() {
        list.push(10); list.push(20); list.push(30);
    }

    function at(uint256 i) external view returns (uint256) {
        return list[i];
    }
}
