// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {DivUnchecked} from "../src/DivUnchecked.sol";

contract DivUncheckedTest is Test {
    function test_UncheckedDivByZero() public {
        DivUnchecked d = new DivUnchecked();
        console.log("unchecked 10 / 0 =", d.div(10, 0));
    }
}
