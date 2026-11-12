// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Vis, Child} from "../src/Vis.sol";

contract VisTest is Test {
    function test_callAll() public {
        Vis v = new Vis();
        assertEq(v.callAll(), 10);
    }

    function test_child() public {
        Child c = new Child();
        assertEq(c.useInternal(), 3);
    }
}
