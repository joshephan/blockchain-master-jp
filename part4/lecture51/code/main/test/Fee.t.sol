// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Fee, FeeChecked} from "../src/Fee.sol";

contract FeeTest is Test {
    function test_Percent101() public {
        Fee f = new Fee();
        f.setPercent(101);
        console.log("percent", f.percent());
    }

    function test_Percent101Checked() public {
        FeeChecked f = new FeeChecked();
        f.setPercent(101);
    }
}
