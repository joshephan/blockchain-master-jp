// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "../src/Market.sol";
import {Collector} from "../src/Collector.sol";
import {MockToken} from "../src/MockToken.sol";

contract CollectorTest is Test {
    MockToken token;
    Collector c;

    event PullFailed(string reason);

    function setUp() public {
        token = new MockToken();
        c = new Collector();
    }

    function test_pull_ok() public {
        assertTrue(c.pull(IERC20(address(token)), 100));
        assertEq(token.balanceOf(address(c)), 100);
    }

    function test_pull_tokenPaused() public {
        token.setBroken(true);
        vm.expectEmit(address(c));
        emit PullFailed("token paused");
        assertFalse(c.pull(IERC20(address(token)), 100));
        assertEq(c.failures(), 1);
        assertEq(token.balanceOf(address(c)), 0);
    }
}
