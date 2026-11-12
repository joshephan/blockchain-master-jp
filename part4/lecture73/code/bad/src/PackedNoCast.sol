// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

struct PositionPacked {
    uint128 deposited;
    uint128 borrowed;
    uint64 lastUpdate;
    bool useAsCollateral;
}

contract PackedNoCast {
    mapping(address asset => mapping(address user => PositionPacked)) public positions;

    function deposit(address asset, uint256 amount) external {
        PositionPacked storage p = positions[asset][msg.sender];
        p.deposited += amount;
        p.lastUpdate = uint64(block.timestamp);
    }
}
