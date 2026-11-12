// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {NoPay} from "../src/NoPay.sol";

contract NoPayMaker {
    function make() external payable returns (NoPay) {
        return new NoPay{value: 1}();
    }
}
