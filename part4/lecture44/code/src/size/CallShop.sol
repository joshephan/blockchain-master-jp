// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IShop} from "../Shop.sol";

contract CallShop {
    uint256 public count;

    function poke() external {
        count += 1;
    }

    function order(address shop) external payable {
        IShop(shop).buy{value: msg.value}(1);
    }
}
