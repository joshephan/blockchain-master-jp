// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Hashes} from "../src/Hashes.sol";

contract TraceTest is Test {
    Hashes h;

    function setUp() public {
        h = new Hashes();
    }

    function test_three() public view {
        h.three();
    }

    function test_recover() public view {
        address got = h.recover(
            0xf32adad13244a267869fe7bb8081a1ab51863121d3ff7810216b8187f4f5225a,
            28,
            0xbc2506ab736f82a3d383b5692f623ba0e487f7a13d2dc1d776b2a68857f004e7,
            0x3cf82f6f5e544ead19fb55e723ebf26df45889c190e465cc3939ecc87af941a7
        );
        assertEq(got, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    }
}
