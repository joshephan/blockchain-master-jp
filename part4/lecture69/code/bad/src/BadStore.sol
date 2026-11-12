// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BadStore {
    uint256[] list;

    function f() public view returns (uint256) {
        return list[1:].length;
    }
}
