// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Child} from "../src/Child.sol";

contract AddrMaker {
    function make(uint256 x) external returns (address) {
        address a = new Child(x);
        return a;
    }
}
