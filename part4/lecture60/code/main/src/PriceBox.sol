// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Price is uint256;

contract PriceBox {
    Price public price;

    function set(uint256 p) external {
        price = Price.wrap(p);
    }

    function get() external view returns (uint256) {
        return Price.unwrap(price);
    }
}
