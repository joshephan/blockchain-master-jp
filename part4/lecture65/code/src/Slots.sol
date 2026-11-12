// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Slots {
    uint256[10] public slots;
    uint256 public tail;

    function set(uint256 i, uint256 v) external {
        slots[i] = v;
    }

    function get(uint256 i) external view returns (uint256) {
        return slots[i];
    }

    function len() external view returns (uint256) {
        return slots.length;
    }

    function clearOne(uint256 i) external {
        delete slots[i];
    }

    function clearAll() external {
        delete slots;
    }
}
