// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

struct Position {
    uint256 deposited;
    uint64 lastUpdate;
}

contract PubStorage {
    function touch(Position storage p) public {
        p.lastUpdate = uint64(block.timestamp);
    }
}
