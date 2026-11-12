// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Places} from "../src/Places.sol";

contract PlacesTest is Test {
    Places p;

    function setUp() public {
        p = new Places();
    }

    function test_twice() public {
        p.bump();
        (uint s, uint m) = p.bump();
        assertEq(s, 2);
        assertEq(m, 1);
    }
}
