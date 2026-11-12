// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Items {
    struct Item {
        address owner;
        uint256 amount;
    }

    Item[] public items;

    function addItem(uint256 amount) external {
        Item storage it = items.push();
        it.owner = msg.sender;
        it.amount = amount;
    }
}
