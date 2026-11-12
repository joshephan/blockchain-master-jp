// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Market.sol";

contract Mine {
    function fee(uint256 price) external pure returns (uint256) {
        return feeOf(price);
    }
}
