// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract PushFixed {
    uint256[10] public slots;

    function add() external {
        slots.push(1);
    }
}
