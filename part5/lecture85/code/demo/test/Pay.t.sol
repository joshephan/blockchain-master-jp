// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Token, Pay} from "../src/Pay.sol";

contract PayTest is Test {
    Token tk;
    Pay p;

    function setUp() public {
        tk = new Token();
        p = new Pay(tk);
        tk.mint(address(p), 100);
    }

    function test_payOne() public {
        p.payOne(address(0xBEEF));
        assertEq(p.seen(), 100);
    }
}
