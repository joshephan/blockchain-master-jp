// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";
import "../src/Slot136.sol";
contract Slot136Test is Test {
    function test_slot() public {
        Slot136 c = new Slot136();
        (uint bs, uint bo, uint is_, uint io, uint vt, uint vs, bytes16 ia) = c.run();
        console.log("b.slot", bs, "b.offset", bo);
        console.log("i.slot", is_, "i.offset", io);
        console.logBytes32(bytes32(vt));
        console.log("sload(b.slot)", vs);
        console.logBytes16(ia);
    }
}
