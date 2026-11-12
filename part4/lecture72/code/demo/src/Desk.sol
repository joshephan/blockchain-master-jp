// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Amount, Position} from "./Types.sol";

contract Desk {
    mapping(address asset => mapping(address user => Position)) public positions;

    event Updated(address asset, address user);

    function open(address asset, uint256 d, uint256 b) external {
        positions[asset][msg.sender] = Position({
            deposited: Amount.wrap(d),
            borrowed: Amount.wrap(b),
            lastUpdate: uint64(block.timestamp),
            useAsCollateral: true
        });
    }

    function updateStorage(address asset, uint256 d, uint256 b) external {
        Position storage p = positions[asset][msg.sender];
        p.deposited = Amount.wrap(d);
        p.borrowed = Amount.wrap(b);
        p.lastUpdate = uint64(block.timestamp);
        emit Updated(asset, msg.sender);
    }

    function updateMemoryForgot(address asset, uint256 d, uint256 b) external {
        Position memory p = positions[asset][msg.sender];
        p.deposited = Amount.wrap(d);
        p.borrowed = Amount.wrap(b);
        p.lastUpdate = uint64(block.timestamp);
        emit Updated(asset, msg.sender);
    }
}
