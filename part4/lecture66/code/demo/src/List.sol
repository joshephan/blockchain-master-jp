// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract List {
    uint256[] public list;

    function add(uint256 v) external {
        list.push(v);
    }

    function removeLast() external {
        list.pop();
    }

    function len() external view returns (uint256) {
        return list.length;
    }

    function get(uint256 i) external view returns (uint256) {
        return list[i];
    }

    function removeAt(uint256 i) external {
        list[i] = list[list.length - 1];
        list.pop();
    }

    function fill(uint256 n) external {
        for (uint256 i = 0; i < n; i++) {
            list.push(i + 1);
        }
    }

    function sum() external view returns (uint256 s) {
        for (uint256 i = 0; i < list.length; i++) {
            s += list[i];
        }
    }
}
