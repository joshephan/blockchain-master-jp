// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Puller, NoReturnToken} from "../src/Shape.sol";

contract ShapeTest is Test {
    Puller p;
    NoReturnToken nr;
    address constant NOBODY = address(0xBEEF);

    function setUp() public {
        p = new Puller();
        nr = new NoReturnToken();
    }

    function test_noReturn() public {
        p.pull(address(nr));
    }

    function test_noCode_returns() public {
        p.pull(NOBODY);
    }

    function test_noCode_noReturns() public {
        p.ping(NOBODY);
    }
}
