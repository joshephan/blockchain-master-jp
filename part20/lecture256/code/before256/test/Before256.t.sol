// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {FeeSwitchToken, NoReturnToken, FalseToken} from "./helpers/OddTokens.sol";

// 標準の統合の前の版(コアロジックの版)で標準と違う動きをするトークン三つ
contract Before256Test is Base {
    TwapFeed f;

    function setUp() public {
        _deploy(0);
        f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
    }

    // 戻り値のないトークン: boolを読もうとしてリバート。受け取れないトークン
    function test_noReturnRejected() public {
        NoReturnToken n = new NoReturnToken();
        market.listAsset(address(n), f, 50, type(uint256).max);
        n.mint(bob, 1000e6);
        vm.startPrank(bob);
        n.approve(address(market), type(uint256).max);
        vm.expectRevert();
        market.deposit(address(n), 1000e6);
        vm.stopPrank();
    }

    // 手数料をオンにしたトークン: 帳簿200、金庫199。先に引き出したbobは100、あとのdaveは100を引き出せない
    function test_feeTokenBreaksPromise() public {
        FeeSwitchToken t = new FeeSwitchToken();
        market.listAsset(address(t), f, 50, type(uint256).max);
        t.mint(bob, 1000e18);
        t.mint(dave, 1000e18);
        vm.prank(bob);
        t.approve(address(market), type(uint256).max);
        vm.prank(dave);
        t.approve(address(market), type(uint256).max);
        vm.prank(bob);
        market.deposit(address(t), 100e18);
        t.setFee(100);
        vm.prank(dave);
        market.deposit(address(t), 100e18);
        assertEq(market.totalDeposits(address(t)), 200e18);
        assertEq(t.balanceOf(address(market)), 199e18);
        t.setFee(0);
        vm.prank(bob);
        market.withdrawAll(address(t));
        vm.prank(dave);
        vm.expectRevert();
        market.withdrawAll(address(t));
    }

    // falseを返すトークンはこの版もTransferFailedで止める
    function test_falseCaught() public {
        FalseToken z = new FalseToken();
        market.listAsset(address(z), f, 50, type(uint256).max);
        vm.prank(bob);
        vm.expectRevert();
        market.deposit(address(z), 1e18);
    }
}
