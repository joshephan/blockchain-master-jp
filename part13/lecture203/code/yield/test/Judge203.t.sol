// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyToken, LendPool202, Farm202, FixedYield202} from "../src/Yield202.sol";

contract Judge203Test is Test {
    ToyToken t;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);

    function setUp() public {
        t = new ToyToken();
        t.mint(alice, 1000);
        t.mint(bob, 1000);
        t.mint(carol, 1000);
    }

    // 新しい預け入れがなければ1日後に最初の人から受け取れなくなる
    function test_fixedYieldNoNextDepositor() public {
        FixedYield202 v = new FixedYield202(t);
        vm.prank(alice);
        v.deposit(1000);
        vm.warp(vm.getBlockTimestamp() + 1 days);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FixedYield202.NoCash.selector, 1000, 1010));
        v.withdraw();
    }

    // 約束した持ち分の合計と金庫の残高を日ごとに比べる
    function test_owedVsCash() public {
        FixedYield202 v = new FixedYield202(t);
        vm.prank(alice);
        v.deposit(1000);
        vm.prank(bob);
        v.deposit(1000);
        vm.prank(carol);
        v.deposit(1000);
        uint256 start = vm.getBlockTimestamp();
        for (uint256 d = 0; d <= 30; d += 10) {
            vm.warp(start + d * 1 days);
            console.log("day", d, "owed", v.totalOwed());
        }
        assertEq(t.balanceOf(address(v)), 3000);
        assertGt(v.totalOwed(), 3000);
    }

    // 先に引き出す人は全額受け取り、最後の人は受け取れない
    function test_firstOutGetsAll() public {
        FixedYield202 v = new FixedYield202(t);
        vm.prank(alice);
        v.deposit(1000);
        vm.prank(bob);
        v.deposit(1000);
        vm.prank(carol);
        v.deposit(1000);
        vm.warp(vm.getBlockTimestamp() + 30 days);
        vm.prank(alice);
        assertEq(v.withdraw(), 1300);
        vm.prank(bob);
        assertEq(v.withdraw(), 1300);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(FixedYield202.NoCash.selector, 400, 1300));
        v.withdraw();
    }

    // 借りた人が返さなければ、預け入れ者は金庫に残った分だけ引き出す
    function test_lendBorrowerNotRepaid() public {
        LendPool202 pool = new LendPool202(t, 1e17);
        vm.prank(alice);
        pool.deposit(1000);
        vm.prank(bob);
        pool.borrow(500);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(pool.cash(), 500);
        vm.prank(alice);
        vm.expectRevert(LendPool202.NoCash.selector);
        pool.withdraw(1000);
        vm.prank(alice);
        assertEq(pool.withdraw(500), 500);
    }

    // 終了時刻のあとは報酬0。発行の権限はトークンのownerの席が決める
    function test_farmEndsAndMinterSeat() public {
        ToyToken r = new ToyToken();
        Farm202 farm = new Farm202(t, r, 1, vm.getBlockTimestamp() + 100);
        r.setMinter(address(farm));
        vm.prank(alice);
        farm.stake(1000);
        vm.warp(vm.getBlockTimestamp() + 200);
        assertEq(farm.pending(alice), 100);
        vm.prank(alice);
        farm.claim();
        vm.warp(vm.getBlockTimestamp() + 1000);
        assertEq(farm.pending(alice), 0);
        assertEq(r.totalSupply(), 100);
        // ownerの席が発行の権限を取り戻して発行する
        r.setMinter(address(this));
        r.mint(address(this), 1_000_000);
        assertEq(r.totalSupply(), 1_000_100);
        vm.prank(alice);
        vm.expectRevert(ToyToken.NotMinter.selector);
        farm.claim();
    }

    // 短い期間の収益を1年に引き延ばした値。倍率は10の18乗
    function test_annualize() public pure {
        uint256 dayRate = 1e15; // 1日0.1%
        uint256 apr = dayRate * 365;
        assertEq(apr, 365e15); // 36.5%
        uint256 x = 1e18;
        for (uint256 i = 0; i < 365; i++) {
            x = x * (1e18 + dayRate) / 1e18;
        }
        uint256 apy = x - 1e18;
        assertApproxEqAbs(apy, 440_251e12, 1e13); // 約44.03%
        uint256 hourAnnual = dayRate * 24 * 365; // 1時間0.1%を1年に
        assertEq(hourAnnual, 8760e15); // 876%
    }
}
