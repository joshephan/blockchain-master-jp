// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

struct Position {
    Amount deposited;
    Amount borrowed;
    uint64 lastUpdate;
    bool useAsCollateral;
}

contract NoEmit {
    Position[] public positions;

    function updateMemoryForgot(uint256 i, uint256 d, uint256 b) external {
        Position memory p = positions[i];
        p.deposited = Amount.wrap(d);
        p.borrowed = Amount.wrap(b);
        p.lastUpdate = uint64(block.timestamp);
    }
}
