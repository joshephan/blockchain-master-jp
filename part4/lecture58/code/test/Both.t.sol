// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Both} from "../src/Both.sol";

contract BothTest is Test {
    function test_LiteralsOnly() public {
        Both x = new Both();
        console.log(x.literalsOnly());
    }
}
