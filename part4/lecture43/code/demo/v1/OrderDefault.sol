// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Shop {
    struct Order {
        address buyer;
        uint256 amount;
    }

    function place(Order calldata order) external pure returns (uint256) {
        return order.amount;
    }
}
