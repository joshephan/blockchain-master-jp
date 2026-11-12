// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

contract PosLoose {
    struct Position {
        Amount deposited;
        uint64 lastUpdate;
        Amount borrowed;
        bool useAsCollateral;
    }

    Position public pos;

    function save(uint256 d, uint256 b) external {
        pos = Position({
            deposited: Amount.wrap(d),
            lastUpdate: uint64(block.timestamp),
            borrowed: Amount.wrap(b),
            useAsCollateral: true
        });
    }
}
