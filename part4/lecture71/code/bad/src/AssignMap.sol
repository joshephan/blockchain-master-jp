// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract AssignMap {
    mapping(address => uint256) m1;
    mapping(address => uint256) m2;

    function copy() external {
        m2 = m1;
    }
}
