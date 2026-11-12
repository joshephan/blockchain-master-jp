// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20} from "../src/Market.sol";

contract TypesTest is Test {
    function test_info() public pure {
        console.logBytes4(type(IERC20).interfaceId);
        console.log("creation", type(Market).creationCode.length);
        console.log("runtime ", type(Market).runtimeCode.length);
    }
}
