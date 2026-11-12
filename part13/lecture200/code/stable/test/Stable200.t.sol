// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FiatUSD} from "../src/FiatUSD.sol";
import {SimpleToken, ToyOracle} from "../src/Toys.sol";
import {VaultUSD} from "../src/VaultUSD.sol";

contract Stable200Test is Test {
    address issuer = makeAddr("issuer");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    FiatUSD fusd;
    SimpleToken col;
    ToyOracle oracle;
    VaultUSD vault;

    function setUp() public {
        vm.roll(10);
        fusd = new FiatUSD(issuer);
        col = new SimpleToken("Collateral", address(this));
        oracle = new ToyOracle(1e18); // COL 1個 = 1ドル
        vault = new VaultUSD(col, oracle);
        col.mint(alice, 150e18);
        vm.roll(11);
    }

    // 法定通貨担保型: 発行体が発行した分だけ増える。準備金を確認する行はない
    function test_issuerMints() public {
        vm.prank(issuer);
        fusd.mint(alice, 100e6);
        assertEq(fusd.totalSupply(), 100e6);
        assertEq(fusd.balanceOf(alice), 100e6);
    }

    function test_onlyIssuerMints() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FiatUSD.NotIssuer.selector, alice));
        fusd.mint(alice, 100e6);
    }

    // 発行体の鍵がアカウントを凍結すると、そのアカウントのトークンは動かない
    function test_frozenCannotTransfer() public {
        vm.startPrank(issuer);
        fusd.mint(alice, 100e6);
        fusd.setFrozen(alice, true);
        vm.stopPrank();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FiatUSD.AccountFrozen.selector, alice));
        fusd.transfer(bob, 10e6);
        assertEq(fusd.balanceOf(alice), 100e6);
    }

    // 償還: トークンをバーンしてイベントだけ残す。ドルが出ていく行はチェーンの外
    function test_redeemBurnsOnly() public {
        vm.prank(issuer);
        fusd.mint(alice, 100e6);
        vm.prank(alice);
        fusd.redeem(40e6);
        assertEq(fusd.totalSupply(), 60e6);
        assertEq(fusd.balanceOf(alice), 60e6);
    }

    // 暗号資産担保型: 担保150ドル相当で100まで
    function test_mintUpToRatio() public {
        vm.startPrank(alice);
        col.approve(address(vault), 150e18);
        vault.deposit(150e18);
        vm.expectRevert(abi.encodeWithSelector(VaultUSD.Undercollateralized.selector, 150e18, 101e18));
        vault.mint(101e18);
        vault.mint(100e18);
        vm.stopPrank();
        assertEq(vault.vusd().balanceOf(alice), 100e18);
        assertEq(col.balanceOf(address(vault)), 150e18);
    }

    // 担保の値が下がると担保率が崩れる。担保トークンの数はそのまま
    function test_priceDropBreaksRatio() public {
        vm.startPrank(alice);
        col.approve(address(vault), 150e18);
        vault.deposit(150e18);
        vault.mint(100e18);
        vm.stopPrank();

        oracle.update(0.8e18);
        vm.roll(12);
        console.log("price 0.8 value", vault.valueOf(alice));
        assertEq(vault.valueOf(alice), 120e18);
        assertFalse(vault.isSafe(alice));

        oracle.update(0.6e18);
        vm.roll(13);
        console.log("price 0.6 value", vault.valueOf(alice));
        assertEq(vault.valueOf(alice), 90e18); // 借金100より小さい
        assertEq(col.balanceOf(address(vault)), 150e18);
        assertEq(vault.vusd().totalSupply(), 100e18);

        // 担保率を下回ると担保を引き出せない
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(VaultUSD.Undercollateralized.selector, 88.8e18, 100e18));
        vault.withdraw(2e18);
    }
}
