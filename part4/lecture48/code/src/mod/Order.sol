// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console} from "forge-std/console.sol";

contract Order {
    uint256 public calls;

    modifier around() {
        console.log("modifier: before _");
        _;
        console.log("modifier: after _");
        calls += 1;
    }

    function run() external around {
        console.log("body");
    }
}
