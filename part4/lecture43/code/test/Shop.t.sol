// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Shop} from "../demo/inherit/Shop.sol";

contract ShopTest is Test {
    function test_PackOne() public {
        Shop shop = new Shop();
        bytes memory out = shop.packOne(7);
        console.logBytes(out);
        assertEq(out.length, 64);
    }
}
