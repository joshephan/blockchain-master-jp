// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {feeOf, FEE_BPS as FEE} from "../src/Shop.sol";

contract UsePick2 {
    function fee(uint256 price) external pure returns (uint256) {
        return feeOf(price) + FEE_BPS;
    }
}
