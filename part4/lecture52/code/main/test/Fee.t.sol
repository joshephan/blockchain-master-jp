// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Fee} from "../src/Fee.sol";
import {Small} from "../src/Small.sol";

contract FeeTest is Test {
    Fee f;

    function setUp() public {
        f = new Fee();
    }

    function test_Table() public view {
        uint256[6] memory xs = [uint256(999), 1000, 1500, 1999, 2000, 12345];
        for (uint256 i = 0; i < xs.length; i++) {
            console.log(xs[i], f.mulFirst(xs[i]), f.divFirst(xs[i]));
        }
    }

    function test_BigMulFirst() public view {
        uint256 amount = 1e75;
        console.log("amount", amount);
        console.log("divFirst", f.divFirst(amount));
        console.log("mulFirst", f.mulFirst(amount));
    }

    function test_SmallDivFirst() public {
        Small s = new Small();
        console.log("divFirst(200)", s.threeQuartersDivFirst(200));
        console.log("divFirst(201)", s.threeQuartersDivFirst(201));
    }

    function test_SmallMulFirst() public {
        Small s = new Small();
        console.log("mulFirst(80)", s.threeQuartersMulFirst(80));
        console.log("mulFirst(200)", s.threeQuartersMulFirst(200));
    }
}
