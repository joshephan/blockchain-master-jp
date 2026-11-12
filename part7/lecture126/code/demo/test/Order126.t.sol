// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console2} from "forge-std/Test.sol";
import {Order126} from "../src/Order126.sol";
contract Order126Test is Test {
    function test_order() public {
        Order126 o = new Order126();
        (uint256 r, uint256[] memory ord) = o.runAddmod();
        console2.log("addmod", r, ord[0] * 100 + ord[1] * 10 + ord[2]);
        (r, ord) = o.runExpr();
        console2.log("expr  ", r, ord[0] * 100 + ord[1] * 10 + ord[2]);
        (r, ord) = o.runPlain();
        console2.log("plain ", r, ord[0] * 100 + ord[1] * 10 + ord[2]);
    }
}
