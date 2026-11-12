// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

struct Position {
    uint256 deposited;
    uint64 lastUpdate;
}

contract ExtStorage {
    function touch(Position storage p) external {
        p.lastUpdate = uint64(block.timestamp);
    }
}
