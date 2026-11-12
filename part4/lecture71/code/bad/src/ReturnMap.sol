// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ReturnMap {
    mapping(address => uint256) deposits;

    function all() external view returns (mapping(address => uint256) storage) {
        return deposits;
    }
}
