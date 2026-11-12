// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {StdToken} from "./StdToken.sol";
import {ToyAmm} from "./amm/ToyAmm.sol";
import {ToyToken} from "./amm/ToyErc20.sol";

// 第52章の確認テスト(デモのコピーにのみ)。Marketのコードはそのまま
contract Amm52Test is Test {
    Market market;
    address alice = address(0xA11CE);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // 第194講: 桁数の違う二つのトークンを預けても、資産ごとに欄が別なので金額を互いに足す行がない
    // 18桁のトークン100個 = 100e18、6桁のトークン100個 = 100e6がそれぞれの欄にそのまま
    function test_amountsStayPerAsset() public {
        StdToken t18 = new StdToken("Eighteen", "E18", 18, 1000e18);
        StdToken t6 = new StdToken("Six", "S6", 6, 1000e6);
        t18.transfer(alice, 100e18);
        t6.transfer(alice, 100e6);
        market.addAsset(IERC20(address(t18)), Ratio.wrap(75));
        market.addAsset(IERC20(address(t6)), Ratio.wrap(75));
        vm.startPrank(alice);
        t18.approve(address(market), 100e18);
        t6.approve(address(market), 100e6);
        market.deposit(address(t18), 100e18);
        market.deposit(address(t6), 100e6);
        vm.stopPrank();
        assertEq(Amount.unwrap(market.totalDeposits(address(t18))), 100e18);
        assertEq(Amount.unwrap(market.totalDeposits(address(t6))), 100e6);
        assertEq(market.collateralCount(alice), 0);
    }

    // 第195講: プールのシェア(LPトークン)もERC-20なので、管理者が上場すれば預けて引き出せる
    // Marketは個数だけを数える。プールの価格が4倍に動いても帳簿のLPの個数はそのまま
    function test_lpTokenDepositsLikeAnyToken() public {
        ToyToken a = new ToyToken(18);
        ToyToken b = new ToyToken(18);
        ToyAmm pool = new ToyAmm(a, b, 0);
        a.mint(alice, 1000 ether);
        b.mint(alice, 1000 ether);
        vm.startPrank(alice);
        a.approve(address(pool), 1000 ether);
        b.approve(address(pool), 1000 ether);
        uint256 shares = pool.addLiquidity(1000 ether, 1000 ether);
        vm.stopPrank();
        assertEq(shares, 1000 ether);

        market.addAsset(IERC20(address(pool)), Ratio.wrap(75));
        vm.startPrank(alice);
        pool.approve(address(market), 400 ether);
        market.deposit(address(pool), 400 ether);
        vm.stopPrank();

        // 外の価格が1 → 4: 裁定取引がBを1000入れる
        address arb = address(0xA4B);
        b.mint(arb, 1000 ether);
        vm.startPrank(arb);
        b.approve(address(pool), 1000 ether);
        pool.swap(address(b), 1000 ether, 0);
        vm.stopPrank();
        assertEq(pool.spotPrice(), 4e18);

        (Amount d,,,) = market.positions(address(pool), alice);
        assertEq(Amount.unwrap(d), 400 ether);
        vm.prank(alice);
        market.withdraw(address(pool), 400 ether);
        assertEq(pool.balanceOf(alice), 1000 ether);
    }
}
