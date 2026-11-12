// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StateBox {
    enum State { Created, Locked, Release, Inactive }

    State public state;

    function bounds() external pure returns (uint8 lo, uint8 hi) {
        lo = uint8(type(State).min);
        hi = uint8(type(State).max);
    }

    function setRaw(uint256 x) external {
        state = State(x);
    }

    function poke(uint256 x) external {
        assembly {
            sstore(state.slot, x)
        }
    }

    function rawSlot() external view returns (uint256 v) {
        assembly {
            v := sload(state.slot)
        }
    }

    function asNumber() external view returns (uint8) {
        return uint8(state);
    }

    function isInactive() external view returns (bool) {
        return state == State.Inactive;
    }
}
