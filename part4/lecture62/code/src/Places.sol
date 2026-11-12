// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Places {
    uint[] public kept;

    function bump() external returns (uint inStorage, uint inMemory) {
        if (kept.length == 0) kept.push(0);
        kept[0] += 1;

        uint[] memory temp = new uint[](1);
        temp[0] += 1;

        return (kept[0], temp[0]);
    }

    function first(uint[] storage xs) internal view returns (uint) {
        return xs[0];
    }

    function readFirst() external view returns (uint) {
        return first(kept);
    }
}
