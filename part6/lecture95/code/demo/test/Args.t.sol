// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Args} from "../src/Args.sol";

contract ArgsTest is Test {
    Args args;

    function setUp() public {
        args = new Args();
    }

    function test_gas() public view {
        uint256[] memory x = new uint256[](50);
        args.extCd(x); // アドレスを一度呼んでおく(コールドアクセスを三つすべてから除く)

        uint256 g0 = gasleft();
        args.extCd(x);
        uint256 g1 = gasleft();
        args.pubCd(x);
        uint256 g2 = gasleft();
        args.pubMem(x);
        uint256 g3 = gasleft();

        console.log("external calldata", g0 - g1);
        console.log("public   calldata", g1 - g2);
        console.log("public   memory  ", g2 - g3);
    }
}
