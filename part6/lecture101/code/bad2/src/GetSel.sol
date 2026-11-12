// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market} from "./Market.sol";

contract GetSel {
    function viaType() external pure returns (bytes4) {
        return Market.status.selector;
    }
}
