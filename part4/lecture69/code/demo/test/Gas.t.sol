// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Slicer} from "../src/Slicer.sol";

contract GasTest is Test {
    Slicer s;

    function setUp() public {
        s = new Slicer();
    }

    function input(uint256 n) internal pure returns (bytes memory b) {
        b = new bytes(n);
        for (uint256 i = 0; i < n; i++) {
            b[i] = bytes1(uint8(i % 255 + 1));
        }
    }

    function test_100() public view {
        s.restLoop(input(100));
        s.restSlice(input(100));
        s.restCopy(input(100));
    }

    function test_200() public view {
        s.restLoop(input(200));
        s.restSlice(input(200));
        s.restCopy(input(200));
    }
}
