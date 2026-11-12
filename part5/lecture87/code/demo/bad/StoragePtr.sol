// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

struct Position {
    uint256 deposited;
    uint64 lastUpdate;
}

contract StoragePtr {
    mapping(address => Position) public positions;

    function touch() external {
        Position storage p;
        p.lastUpdate = uint64(block.timestamp);
    }
}
