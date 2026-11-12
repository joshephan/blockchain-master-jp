// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Shop} from "../Shop.sol";

contract MakeShop {
    uint256 public count;

    function poke() external {
        count += 1;
    }

    function make() external returns (address) {
        return address(new Shop());
    }
}
