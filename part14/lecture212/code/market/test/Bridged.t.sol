// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {BridgedToken} from "./BridgedToken.sol";

// 第211講: ブリッジトークンもMarketにとっては他のトークンと同じアドレス一つ。Marketはトークンの裏の金庫・検証を見ない
// トークン側の停止権限はMarketの出金まで届く(信頼の前提の第211講の行)
contract BridgedTest is Test {
    Market market;
    BridgedToken bt;
    address minter = address(0x317);
    address guardian = address(0x6A);
    address bob = address(0xB0B);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        bt = new BridgedToken(minter, guardian);
        vm.prank(minter);
        bt.mint(bob, 100);
        market.addAsset(IERC20(address(bt)), Ratio.wrap(75));
        vm.startPrank(bob);
        bt.approve(address(market), 100);
        market.deposit(address(bt), 100);
        vm.stopPrank();
    }

    function test_bridgedTokenListedLikeAny() public {
        vm.prank(bob);
        market.withdraw(address(bt), 30);
        (Amount d,,,) = market.positions(address(bt), bob);
        assertEq(Amount.unwrap(d), 70);
        assertEq(bt.balanceOf(bob), 30);
        assertEq(bt.balanceOf(address(market)), 70);
    }

    function test_tokenPauseBlocksWithdraw() public {
        vm.prank(guardian);
        bt.setPaused(true);
        vm.prank(bob);
        vm.expectRevert(BridgedToken.TokenPaused.selector);
        market.withdraw(address(bt), 30);
        vm.prank(bob);
        vm.expectRevert(BridgedToken.TokenPaused.selector);
        market.withdrawAll(address(bt));
        (Amount d,,,) = market.positions(address(bt), bob);
        assertEq(Amount.unwrap(d), 100);
        vm.prank(guardian);
        bt.setPaused(false);
        vm.prank(bob);
        market.withdraw(address(bt), 30);
        assertEq(bt.balanceOf(bob), 30);
    }
}
