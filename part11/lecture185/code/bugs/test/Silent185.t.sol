// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Silent185} from "../src/Silent185.sol";

contract Silent185Test is Test {
    Silent185 s = new Silent185();

    function test_shiftSignedRoundsDown() public view {
        console.log("-5 >> 1");
        console.logInt(s.shiftSigned(-5));
        assertEq(s.shiftSigned(-5), -3);
    }

    function test_powTypeIsBase() public {
        console.log("uint8 2 ** 7", s.powBase(2, 7));
        vm.expectRevert(stdError.arithmeticError);
        s.powBase(2, 8);
    }

    function test_shiftLiteralIsUint256() public view {
        console.log("1 << uint8 8", s.shiftLiteral(8));
        assertEq(s.shiftLiteral(8), 256);
    }
}
