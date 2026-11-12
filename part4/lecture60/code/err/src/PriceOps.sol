// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Price is uint256;

contract PriceOps {
    function bump(Price p, uint256 x) external pure returns (Price) {
        return p + x;
    }

    function sum(Price a, Price b) external pure returns (Price) {
        return a + b;
    }
}
