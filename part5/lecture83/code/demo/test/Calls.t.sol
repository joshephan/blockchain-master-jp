// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Caller, RevertToken} from "../src/Caller.sol";
import {MockToken, FalseToken} from "../src/Tokens.sol";

contract CallsTest is Test {
    Caller c;
    RevertToken rt;
    FalseToken ft;
    address alice = address(0xA11CE);
    address empty = address(0xdEaD);

    function setUp() public {
        c = new Caller();
        rt = new RevertToken();
        ft = new FalseToken();
    }

    function test_typedRevert() public {
        c.typed(address(rt), alice, 500);
    }

    function test_lowRevert() public {
        (bool ok, bytes memory ret) = c.low(address(rt), alice, 500);
        console.log("ok", ok);
        console.logBytes(ret);
    }

    function test_typedFalse() public {
        bool r = c.typed(address(ft), alice, 500);
        console.log("returned", r);
    }

    function test_lowFalse() public {
        (bool ok, bytes memory ret) = c.low(address(ft), alice, 500);
        console.log("ok", ok);
        console.logBytes(ret);
    }

    function test_typedEmpty() public {
        c.typed(empty, alice, 500);
    }

    function test_lowEmpty() public {
        (bool ok, bytes memory ret) = c.low(empty, alice, 500);
        console.log("ok", ok);
        console.logBytes(ret);
    }
}
