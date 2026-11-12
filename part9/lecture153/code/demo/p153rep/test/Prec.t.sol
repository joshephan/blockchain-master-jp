// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Prec} from "../src/Prec.sol";

contract PrecTest is Test {
    function test_alwaysFalse() public {
        Prec p = new Prec();
        for (uint160 x = 0; x < 300; x++) {
            assertFalse(p.f(x));
        }
    }
}
