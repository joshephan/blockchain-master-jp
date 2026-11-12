// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {State, Order} from "./types/Types.sol";

contract Shop {
    State public state;
    Order public order;

    function lock() external {
        state = State.Locked;
    }
}
