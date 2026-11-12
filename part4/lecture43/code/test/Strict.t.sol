// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Small_v1} from "../demo/strict/Small_v1.sol";
import {Small_v2} from "../demo/strict/Small_v2.sol";

contract StrictTest is Test {
    function test_Send300() public {
        bytes memory data = abi.encodeWithSignature("echo(uint8)", uint256(300));
        (bool ok1, bytes memory out1) = address(new Small_v1()).call(data);
        (bool ok2, bytes memory out2) = address(new Small_v2()).call(data);
        console.log("v1 ok:", ok1);
        if (ok1) console.log("v1 returned:", abi.decode(out1, (uint256)));
        console.log("v2 ok:", ok2);
        console.log("v2 return length:", out2.length);
    }
}
