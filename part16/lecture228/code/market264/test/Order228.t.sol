// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {IMarket} from "../src/IMarket.sol";
import {console} from "forge-std/Test.sol";

// 第228講の確認テスト。Marketのsrcは変えない(キャップストーン末の版のコピー)
// 預け入れ・引き出しは順番を変えてもそれぞれの帳簿が同じ。清算は先に入った一つだけが成功
contract Order228Test is Base {
    function setUp() public {
        _deploy(0);
    }

    function _dep(address who, uint256 amt) internal {
        vm.prank(who);
        market.deposit(address(usd), amt);
    }

    function _wd(address who, uint256 amt) internal {
        vm.prank(who);
        market.withdraw(address(usd), amt);
    }

    // aliceが先 / bobが先: 入れて出す四つの取引の順番だけを変える
    function test_orderDoesNotMoveShares() public {
        uint256 snap = vm.snapshotState();
        _dep(alice, 200e6);
        _dep(bob, 100e6);
        _wd(alice, 50e6);
        _wd(bob, 30e6);
        uint256[4] memory first = [
            market.depositOf(address(usd), alice),
            market.depositOf(address(usd), bob),
            usd.balanceOf(alice),
            usd.balanceOf(bob)
        ];
        vm.revertToState(snap);
        _dep(bob, 100e6);
        _wd(bob, 30e6);
        _dep(alice, 200e6);
        _wd(alice, 50e6);
        uint256[4] memory second = [
            market.depositOf(address(usd), alice),
            market.depositOf(address(usd), bob),
            usd.balanceOf(alice),
            usd.balanceOf(bob)
        ];
        for (uint256 i; i < 4; i++) {
            console.log(first[i], second[i]);
            assertEq(first[i], second[i]);
        }
    }

    // 他の人が自分の取引の直前に大きく入れても、自分が引き出す量は自分が入れた量
    function test_bigDepositBeforeMeChangesNothing() public {
        _dep(alice, 100e6);
        _dep(bob, 3000e6);
        _wd(alice, 100e6);
        console.log("alice usd", usd.balanceOf(alice));
        assertEq(usd.balanceOf(alice), 10_000e6);
        assertEq(market.depositOf(address(usd), alice), 0);
        assertEq(market.depositOf(address(usd), bob), 3000e6);
    }

    // 同じポジションをcarol・daveが清算: どちらが先でも借りたaliceの帳簿は同じで、ボーナスを受け取る側だけが変わる
    function test_liquidationOrderPicksWinnerOnly() public {
        _openPosition();
        _price(0.85e18);
        uint256 snap = vm.snapshotState();
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 350e6);
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 386e18, 350e18));
        market.liquidate(alice, address(usd), address(col), 350e6);
        uint256 debtA = market.debtOf(address(usd), alice);
        uint256 colA = market.depositOf(address(col), alice);
        uint256 carolCol = market.depositOf(address(col), carol);
        vm.revertToState(snap);
        vm.prank(dave);
        market.liquidate(alice, address(usd), address(col), 350e6);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotLiquidatable.selector, 386e18, 350e18));
        market.liquidate(alice, address(usd), address(col), 350e6);
        console.log("alice debt", debtA, market.debtOf(address(usd), alice));
        console.log("alice col", colA, market.depositOf(address(col), alice));
        console.log("winner col", carolCol, market.depositOf(address(col), dave));
        assertEq(debtA, market.debtOf(address(usd), alice));
        assertEq(colA, market.depositOf(address(col), alice));
        assertEq(carolCol, market.depositOf(address(col), dave));
    }
}
