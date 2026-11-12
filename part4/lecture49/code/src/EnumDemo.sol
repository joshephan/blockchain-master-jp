// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract EnumDemo {
    enum State { Created, Locked, Release, Inactive }
    State public state;

    function set(State s) external {
        state = s;
    }

    function setRaw(uint256 x) external {
        state = State(x);
    }

    function locked() external pure returns (uint8) {
        return uint8(State.Locked);
    }
}
