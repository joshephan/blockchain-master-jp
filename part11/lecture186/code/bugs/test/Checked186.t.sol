// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Checked186} from "../src/Checked186.sol";

contract Checked186Test is Test {
    Checked186 c = new Checked186();

    function test_subPanics() public {
        vm.expectRevert(stdError.arithmeticError);
        c.sub(5, 6);
    }

    function test_subWrapWraps() public view {
        console.log("unchecked 5 - 6", c.subWrap(5, 6));
        assertEq(c.subWrap(5, 6), type(uint256).max);
    }

    function test_mulPanicsAndWrapIsZero() public {
        uint256 half = 2 ** 255;
        console.log("unchecked 2 * 2**255", c.mulWrap(2, half));
        assertEq(c.mulWrap(2, half), 0);
        vm.expectRevert(stdError.arithmeticError);
        c.mul(2, half);
    }

    function test_uncheckedDoesNotReachCalledFunction() public {
        vm.expectRevert(stdError.arithmeticError);
        c.subViaCall(5, 6);
    }

    function test_divByZeroStillReverts() public {
        vm.expectRevert(stdError.divisionError);
        c.divWrap(1, 0);
    }

    function test_conversionNotChecked() public view {
        uint256 big = uint256(type(uint64).max) + 1;
        console.log("uint64(2**64)", c.narrow(big));
        assertEq(c.narrow(big), 0);
    }

    function test_powRightAssoc() public view {
        console.log("2 ** 3 ** 2", c.powChain());
        assertEq(c.powChain(), 512);
    }

    function test_negMinPanics() public {
        vm.expectRevert(stdError.arithmeticError);
        c.negMin(type(int8).min);
    }

    function test_panicCodes() public {
        vm.expectRevert(stdError.assertionError);
        c.failAssert();
        vm.expectRevert(stdError.enumConversionError);
        c.toKind(5);
        vm.expectRevert(stdError.popError);
        c.popEmpty();
        vm.expectRevert(stdError.indexOOBError);
        c.at(0);
    }
}
