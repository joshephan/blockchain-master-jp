// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Saver, Target} from "../src/Saver.sol";

contract SaverTest is Test {
    function test_save() public {
        Saver s = new Saver();
        Target t = new Target();
        s.save(t.check);
        console.log(address(t));
        console.logBytes32(vm.load(address(s), bytes32(uint256(0))));
    }
}
