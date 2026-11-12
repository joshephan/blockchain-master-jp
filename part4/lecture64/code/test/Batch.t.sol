// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Batch} from "../src/Batch.sol";

contract BatchTest is Test {
    Batch b;

    function setUp() public {
        b = new Batch();
    }

    function _list(uint256 n) internal pure returns (uint256[] memory xs) {
        xs = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            xs[i] = i + 1;
        }
    }

    function test_AddAll10() public {
        b.addAll(_list(10));
        assertEq(b.total(), 55);
    }

    function test_AddAll100() public {
        b.addAll(_list(100));
        assertEq(b.total(), 5050);
    }
}
