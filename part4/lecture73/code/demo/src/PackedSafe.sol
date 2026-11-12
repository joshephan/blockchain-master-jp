// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {PositionPacked} from "./Packed.sol";

contract MarketPackedSafe {
    mapping(address asset => mapping(address user => PositionPacked)) public positions;

    function deposit(address asset, uint256 amount) external {
        require(amount <= type(uint128).max, "amount too large");
        PositionPacked storage p = positions[asset][msg.sender];
        p.deposited += uint128(amount);
        p.lastUpdate = uint64(block.timestamp);
    }
}
