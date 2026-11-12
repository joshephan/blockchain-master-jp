// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MemToStorage {
    uint[] public x;

    function f() external {
        uint[] memory m = new uint[](3);
        uint[] storage s = m;
        s[0] = 1;
    }
}
