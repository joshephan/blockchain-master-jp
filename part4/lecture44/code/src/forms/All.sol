// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Shop.sol";

contract UseAll {
    function fee(uint256 price) external pure returns (uint256) {
        return feeOf(price) + FEE_BPS;
    }
}
