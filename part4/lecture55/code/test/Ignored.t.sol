// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ignored} from "../src/Ignored.sol";
import {Refuser} from "../src/Receivers.sol";

contract IgnoredTest is Test {
    function test_Ignored() public {
        Ignored g = new Ignored{value: 10 ether}();
        address r = address(new Refuser());
        g.sendIgnored(payable(r));
        g.callIgnored(r);
        console.log("reached", g.reached());
        console.log("refuser balance", r.balance);
        console.log("ignored balance", address(g).balance);
    }
}
