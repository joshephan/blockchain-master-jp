// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Child} from "../src/Child.sol";

contract ValueMaker {
    function make(uint256 x) external payable returns (Child) {
        return new Child{value: msg.value}(x);
    }
}
