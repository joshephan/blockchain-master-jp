// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

enum State { Created, Locked, Release, Inactive }

struct Order {
    uint128 amount;
    uint64 createdAt;
    bool paid;
    uint256 orderId;
}
