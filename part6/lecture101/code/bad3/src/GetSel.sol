// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market} from "./Market.sol";

contract GetSel {
    function viaInstance() external pure returns (bytes4) {
        Market m = Market(address(0));
        return m.status.selector;
    }
}
