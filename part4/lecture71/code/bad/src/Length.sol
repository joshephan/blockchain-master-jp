// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Length {
    mapping(address => uint256) public deposits;

    function count() external view returns (uint256) {
        return deposits.length;
    }
}
