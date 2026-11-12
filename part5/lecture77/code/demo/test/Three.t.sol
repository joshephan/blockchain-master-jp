// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Receiver, Sender} from "../src/Three.sol";

contract ThreeTest is Test {
    function test_three() public {
        Receiver r = new Receiver();
        Sender s = new Sender();
        s.viaTransfer{value: 1 gwei}(payable(address(r)));
        s.viaSend{value: 2 gwei}(payable(address(r)));
        s.viaCall{value: 3 gwei}(payable(address(r)));
    }
}
