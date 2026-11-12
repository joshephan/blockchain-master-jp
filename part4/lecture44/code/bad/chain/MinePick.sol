// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Market} from "../../src/chain/Market.sol";

contract MinePick {
    function fee(uint256 price) external pure returns (uint256) {
        return feeOf(price);
    }
}
