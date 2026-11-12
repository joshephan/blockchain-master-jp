// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SetLength {
    uint256[10] public slots;

    function grow() external {
        slots.length = 20;
    }
}
