// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Price is uint256;

using {add as +} for Price global;

function add(Price a, Price b) pure returns (Price) {
    return Price.wrap(Price.unwrap(a) + Price.unwrap(b));
}

contract PriceOperator {
    function sum(Price a, Price b) external pure returns (Price) {
        return a + b;
    }
}
