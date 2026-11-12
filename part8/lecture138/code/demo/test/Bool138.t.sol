// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";
contract Bool138Test is Test {
    function test_dirtyBoolEqOne() public pure {
        bool b;
        uint256 eqOne;
        uint256 masked;
        assembly { b := 2 eqOne := eq(b, 1) masked := and(0x1ff, 0xff) }
        console.log("eq(b, 1) in block", eqOne);
        console.log("and(0x1ff, 0xff)", masked);
    }
}
