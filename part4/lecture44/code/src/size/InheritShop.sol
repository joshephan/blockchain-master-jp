// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Shop} from "../Shop.sol";

contract InheritShop is Shop {
    uint256 public count;

    function poke() external {
        count += 1;
    }
}
