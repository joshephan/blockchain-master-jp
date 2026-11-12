// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Amount} from "./Loose.sol";

contract PosTight {
    struct Position {
        Amount deposited;
        Amount borrowed;
        uint64 lastUpdate;
        bool useAsCollateral;
    }

    Position public pos;

    function save(uint256 d, uint256 b) external {
        pos = Position({
            deposited: Amount.wrap(d),
            borrowed: Amount.wrap(b),
            lastUpdate: uint64(block.timestamp),
            useAsCollateral: true
        });
    }
}
