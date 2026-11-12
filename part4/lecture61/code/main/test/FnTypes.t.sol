// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FnTypes} from "../src/FnTypes.sol";
import {Runner, Alice, Bob} from "../src/Runner.sol";

contract FnTypesTest is Test {
    FnTypes f;
    Runner r;
    Alice a;
    Bob b;

    function setUp() public {
        f = new FnTypes();
        r = new Runner();
        a = new Alice();
        b = new Bob();
    }

    function test_internal() public view {
        assertEq(f.useInternal(5), 25);
    }

    function test_external() public view {
        assertEq(f.useExternal(5), 10);
    }

    function test_parts() public view {
        (address at, bytes4 sel) = f.parts();
        console.log(at);
        console.logBytes4(sel);
        console.log(address(f));
    }

    function test_emptyInner() public view {
        f.callEmptyInner(1);
    }

    function test_emptyOuter() public {
        f.callEmptyOuter(1);
    }

    function test_runAlice() public {
        vm.prank(address(0xA11CE));
        r.run(5, a.onDone);
        assertEq(a.got(), 10);
    }

    function test_runBob() public {
        vm.prank(address(0xB0B));
        r.run(5, b.ping);
        assertEq(b.lastCaller(), address(r));
    }
}
