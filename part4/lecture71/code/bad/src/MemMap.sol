// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MemMap {
    function f() external pure {
        mapping(address => uint256) memory m;
    }
}
