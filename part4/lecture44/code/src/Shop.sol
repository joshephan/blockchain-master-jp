// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

uint256 constant FEE_BPS = 100;

error SoldOut(uint256 itemId);

struct Order {
    address buyer;
    uint256 itemId;
}

enum Status { Open, Closed }

function feeOf(uint256 price) pure returns (uint256) {
    return price * FEE_BPS / 10_000;
}

interface IShop {
    function buy(uint256 itemId) external payable;
}

library PriceLib {
    function withFee(uint256 price) internal pure returns (uint256) {
        return price + feeOf(price);
    }
}

contract Shop is IShop {
    mapping(uint256 => bool) public sold;

    function buy(uint256 itemId) external payable {
        if (sold[itemId]) revert SoldOut(itemId);
        sold[itemId] = true;
    }
}
