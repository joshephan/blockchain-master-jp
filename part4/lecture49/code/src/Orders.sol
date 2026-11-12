// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract OrderLoose {
    struct Order {
        uint128 amount;
        uint256 orderId;
        uint64 createdAt;
        bool paid;
    }

    Order public order;

    function save(uint128 amount, uint256 orderId, uint64 createdAt) external {
        order = Order(amount, orderId, createdAt, true);
    }
}

contract OrderTight {
    struct Order {
        uint128 amount;
        uint64 createdAt;
        bool paid;
        uint256 orderId;
    }

    Order public order;

    function save(uint128 amount, uint256 orderId, uint64 createdAt) external {
        order = Order({amount: amount, createdAt: createdAt, paid: true, orderId: orderId});
    }
}
