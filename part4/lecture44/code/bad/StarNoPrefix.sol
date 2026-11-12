// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import * as S from "../src/Shop.sol";

contract UseStar2 {
    function fee(uint256 price) external pure returns (uint256) {
        return feeOf(price);
    }
}
