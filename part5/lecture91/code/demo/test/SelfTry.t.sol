// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SelfTry, Factory} from "../src/SelfTry.sol";

contract SelfTryTest is Test {
    function test_this() public {
        SelfTry s = new SelfTry();
        console.log("run(1):", s.run(1));
        console.log("run(0):", s.run(0));
    }

    function test_new() public {
        Factory f = new Factory();
        address next = vm.computeCreateAddress(address(f), vm.getNonce(address(f)));
        address got = f.make(0);
        console.log("make(0) returned", got);
        console.log("code at next    ", next.code.length);
        console.log("factory nonce   ", vm.getNonce(address(f)));
        address got2 = f.make(7);
        console.log("make(7) returned", got2);
    }
}
