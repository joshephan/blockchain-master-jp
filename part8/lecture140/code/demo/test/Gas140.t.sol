// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Worker, Caller} from "../src/Gas140.sol";

contract Gas140Test is Test {
    function test_fixedGas() public {
        Worker w = new Worker();
        Caller c = new Caller();
        (bool ok, uint256 r) = c.tryWork(w, 20, 5000);
        console.log("ok", ok);
        console.log("r", r);
        uint256 g0 = gasleft();
        w.work(20);
        console.log("work(20) gas", g0 - gasleft());
        assertTrue(ok);
    }
}
