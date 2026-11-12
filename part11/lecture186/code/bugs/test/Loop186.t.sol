// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Loop186} from "../src/Loop186.sol";

contract Loop186Test is Test {
    Loop186 l = new Loop186();

    function test_loopGas() public view {
        uint256 g = gasleft();
        l.forLoop(100);
        console.log("for ++i       ", g - gasleft());
        g = gasleft();
        l.forUnchecked(100);
        console.log("for unchecked ", g - gasleft());
        g = gasleft();
        l.whileLoop(100);
        console.log("while ++i     ", g - gasleft());
    }
}
