// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract PopValue {
    uint256[] public list;

    function take() external returns (uint256) {
        uint256 x = list.pop();
        return x;
    }
}
