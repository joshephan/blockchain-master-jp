// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import * as S from "../Shop.sol";

contract UseStar {
    function fee(uint256 price) external pure returns (uint256) {
        return S.feeOf(price) + S.FEE_BPS;
    }
}
