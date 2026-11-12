// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyAmm} from "../src/ToyAmm.sol";
import {ToyToken} from "../src/ToyErc20.sol";
import {GuardedSwap} from "../src/GuardedSwap.sol";

// 第228講: ユーザー側の防御。受け取る最小量と締め切り時刻
contract Guard228Test is Test {
    ToyToken a;
    ToyToken b;
    ToyAmm pool;
    GuardedSwap gs;
    address user = address(0xA11CE);
    address other = address(0xB0B);

    function setUp() public {
        a = new ToyToken(18);
        b = new ToyToken(18);
        pool = new ToyAmm(a, b, 30);
        a.mint(address(this), 1000 ether);
        b.mint(address(this), 1000 ether);
        a.approve(address(pool), 1000 ether);
        b.approve(address(pool), 1000 ether);
        pool.addLiquidity(1000 ether, 1000 ether);
        gs = new GuardedSwap();
        a.mint(user, 100 ether);
        vm.prank(user);
        a.approve(address(gs), type(uint256).max);
        a.mint(other, 300 ether);
        vm.prank(other);
        a.approve(address(pool), type(uint256).max);
    }

    // 送るときに見た値から0.5%だけ譲った最小量
    function _minOut(uint256 amountIn) internal view returns (uint256 q, uint256 m) {
        q = pool.quote(address(a), amountIn);
        m = q * 995 / 1000;
    }

    function test_passesWhenNothingMoved() public {
        (uint256 q, uint256 m) = _minOut(100 ether);
        vm.prank(user);
        uint256 out = gs.swap(pool, a, b, 100 ether, m, vm.getBlockTimestamp() + 120);
        console.log("quote", q);
        console.log("minOut", m);
        console.log("out", out);
        assertEq(out, q);
    }

    // ユーザーが送ったあと、他の人の普通の大きな交換が先に入って価格が動く
    function test_minOutStopsWorsePrice() public {
        (uint256 q, uint256 m) = _minOut(100 ether);
        vm.prank(other);
        pool.swap(address(a), 300 ether, 0);
        uint256 nowQ = pool.quote(address(a), 100 ether);
        console.log("quote at send", q);
        console.log("quote at run", nowQ);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ToyAmm.Slippage.selector, nowQ, m));
        gs.swap(pool, a, b, 100 ether, m, vm.getBlockTimestamp() + 120);
    }

    // 最小量が0なら同じ状況でそのまま約定
    function test_zeroMinOutTakesWorsePrice() public {
        (uint256 q,) = _minOut(100 ether);
        vm.prank(other);
        pool.swap(address(a), 300 ether, 0);
        vm.prank(user);
        uint256 out = gs.swap(pool, a, b, 100 ether, 0, vm.getBlockTimestamp() + 120);
        console.log("quote at send", q);
        console.log("out", out);
        assertLt(out, q);
    }

    // 待合室に長くとどまった取引: 締め切り時刻が過ぎればプールを呼ぶ前にリバート
    function test_deadlinePassed() public {
        (, uint256 m) = _minOut(100 ether);
        uint256 deadline = vm.getBlockTimestamp() + 120;
        vm.warp(vm.getBlockTimestamp() + 600);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedSwap.Expired.selector, deadline, vm.getBlockTimestamp()));
        gs.swap(pool, a, b, 100 ether, m, deadline);
    }
}
