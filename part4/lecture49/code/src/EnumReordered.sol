// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract EnumReordered {
    enum State { Locked, Created, Release, Inactive }

    function locked() external pure returns (uint8) {
        return uint8(State.Locked);
    }
}
