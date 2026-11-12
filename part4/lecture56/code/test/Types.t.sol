// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, Token, FakeToken, Pool, Prober} from "../src/Types.sol";

contract TypesTest is Test {
    address constant EMPTY = 0x000000000000000000000000000000000000dEaD;
    Token token;
    FakeToken fake;
    Prober prober;

    function setUp() public {
        token = new Token();
        fake = new FakeToken();
        prober = new Prober();
    }

    function test_PayTrace() public {
        Pool pool = new Pool(IERC20(address(token)));
        token.transfer(address(pool), 100);
        pool.pay(address(0xB0b), 30);
    }

    function test_WithReturn() public {
        prober.withReturn(EMPTY);
    }

    function test_NoReturn() public {
        prober.noReturn(EMPTY);
    }

    function test_LowLevel() public {
        (bool ok, bytes memory data) = prober.lowLevel(EMPTY);
        console.log("ok", ok);
        console.log("data length", data.length);
    }

    function test_CodeLength() public view {
        console.log("token", prober.codeLength(address(token)));
        console.log("fake", prober.codeLength(address(fake)));
        console.log("empty", prober.codeLength(EMPTY));
    }

    function test_FakePasses() public {
        Pool pool = new Pool(IERC20(address(fake)));
        console.log("code length", address(pool.asset()).code.length);
        console.log("pay", pool.pay(address(0xB0b), 30));
    }
}
