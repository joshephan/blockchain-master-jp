// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Wrap} from "../src/Wrap.sol";

contract WrapTest is Test {
    Wrap w;

    function setUp() public {
        w = new Wrap();
    }

    function test_MaxPlusOne() public view {
        w.add(type(uint256).max, 1);
    }

    function test_ZeroMinusOne() public view {
        w.sub(0, 1);
    }

    function test_Int8MaxPlusOne() public view {
        w.addInt8(127, 1);
    }

    function test_MaxPlusOneUnchecked() public view {
        console.log(w.addUnchecked(type(uint256).max, 1));
    }

    function test_ZeroMinusOneUnchecked() public view {
        console.log(w.subUnchecked(0, 1));
    }

    function test_TwoTimesHalfChecked() public view {
        w.mul(2, 2 ** 255);
    }

    function test_TwoTimesHalf() public view {
        console.log(w.mulUnchecked(2, 2 ** 255));
    }
}
