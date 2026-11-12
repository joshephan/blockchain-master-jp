// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {PureThree} from "../src/PureThree.sol";

contract PureThreeTest is Test {
    PureThree t;

    function setUp() public {
        t = new PureThree();
    }

    function test_all() public view {
        t.takeAll(100);
    }

    function test_one() public view {
        t.takeOne(100);
    }
}
