// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {C, D, OnlyB, E, F, G} from "../src/Super.sol";

contract SuperTest is Test {
    function test_who() public {
        console.log(new C().who());
        console.log(new D().who());
        console.log(new OnlyB().who());
        console.log(new E().who());
        console.log(new F().who());
        console.log(new G().who());
    }
}
