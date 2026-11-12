// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {BlockInfo} from "../src/BlockInfo.sol";
import {Market, IERC20, Ratio} from "../src/Market.sol";

contract HeaderTest is Test {
    BlockInfo info;

    function setUp() public {
        info = new BlockInfo();
    }

    function test_cheats() public {
        vm.warp(1900000000);
        vm.roll(12345);
        vm.prevrandao(bytes32(uint256(42)));
        vm.fee(7 gwei);
        vm.coinbase(address(0xC0DE));
        vm.chainId(5);
        (uint256 number, uint256 timestamp, uint256 basefee, , address coinbase, uint256 prevrandao) = info.header();
        assertEq(timestamp, 1900000000);
        assertEq(number, 12345);
        assertEq(prevrandao, 42);
        assertEq(basefee, 7 gwei);
        assertEq(coinbase, address(0xC0DE));
        assertEq(info.chain(), 5);
    }

    function test_blockhash() public {
        vm.roll(1000);
        assertEq(info.hashOf(1000), bytes32(0)); // 今のブロック
        assertEq(info.hashOf(1001), bytes32(0)); // これから来るブロック
        assertEq(info.hashOf(743), bytes32(0));  // 257ブロック前
    }

    function test_elapsed() public {
        Market market = new Market();
        address asset = address(0xAAAA);
        address alice = address(0xA11CE);
        market.addAsset(IERC20(asset), Ratio.wrap(75));
        vm.warp(1900000000);
        vm.prank(alice);
        market.deposit(asset, 500);
        assertEq(market.elapsedOf(asset, alice), 0);
        vm.warp(1900000000 + 1 days);
        assertEq(market.elapsedOf(asset, alice), 86400);
    }
}
