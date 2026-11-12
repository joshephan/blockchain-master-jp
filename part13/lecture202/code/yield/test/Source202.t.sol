// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyToken, LendPool202, FeePool202, Farm202, FixedYield202} from "../src/Yield202.sol";

contract Source202Test is Test {
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

    // 出どころ1: 預け入れ者の持ち分が増えた50は、bobがrepayで入れた50
    function test_interestFromBorrower() public {
        LendPool202 pool = new LendPool202(t, 1e17); // 年10%
        vm.prank(alice);
        pool.deposit(1000);
        vm.prank(bob);
        pool.borrow(500);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(pool.owed(), 550);
        vm.prank(bob);
        pool.repay();
        assertEq(t.balanceOf(bob), 950);
        vm.prank(alice);
        uint256 got = pool.withdraw(1000);
        assertEq(got, 1050);
        console.log("alice got", got, "bob left", t.balanceOf(bob));
    }

    // 借りた人がいなければ1年たってもそのまま
    function test_noBorrowerNoInterest() public {
        LendPool202 pool = new LendPool202(t, 1e17);
        vm.prank(alice);
        pool.deposit(1000);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        vm.prank(alice);
        assertEq(pool.withdraw(1000), 1000);
    }

    // 出どころ2: 取引した人が払った手数料がプールに残る
    function test_feeFromTraders() public {
        ToyToken b = new ToyToken();
        b.mint(alice, 1000);
        b.mint(bob, 1000);
        FeePool202 pool = new FeePool202(t, b);
        vm.prank(alice);
        pool.addLiquidity(1000, 1000);
        vm.startPrank(bob);
        uint256 outB = pool.swapAForB(100);
        uint256 outA = pool.swapBForA(outB);
        vm.stopPrank();
        console.log("bob swap A100 -> B", outB, "-> A", outA);
        (uint256 rA, uint256 rB) = pool.removeAll(alice);
        console.log("alice removes A", rA, "B", rB);
        assertGt(rA * rB, 1000 * 1000);
        assertEq(t.balanceOf(bob) + b.balanceOf(bob) + rA + rB, 4000);
    }

    // 出どころ3: 報酬は新しく発行したトークン。供給量がその分増える
    function test_rewardIsMinted() public {
        ToyToken r = new ToyToken();
        Farm202 farm = new Farm202(t, r, 1, vm.getBlockTimestamp() + 100);
        r.setMinter(address(farm));
        vm.prank(alice);
        farm.stake(1000);
        vm.warp(vm.getBlockTimestamp() + 50);
        vm.prank(alice);
        farm.claim();
        assertEq(r.balanceOf(alice), 50);
        assertEq(r.totalSupply(), 50);
        assertEq(t.balanceOf(address(farm)), 1000);
    }

    // 出どころ4: 先に入った人が受け取った利息は、あとから入った人の元本
    function test_paidByNextDepositor() public {
        FixedYield202 v = new FixedYield202(t);
        vm.prank(alice);
        v.deposit(1000);
        vm.warp(vm.getBlockTimestamp() + 10 days);
        vm.prank(bob);
        v.deposit(1000);
        vm.warp(vm.getBlockTimestamp() + 10 days);
        assertEq(v.owedTo(alice), 1200);
        assertEq(v.owedTo(bob), 1100);
        assertEq(v.totalOwed(), 2300);
        assertEq(t.balanceOf(address(v)), 2000);
        vm.prank(alice);
        assertEq(v.withdraw(), 1200);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(FixedYield202.NoCash.selector, 800, 1100));
        v.withdraw();
    }
}
