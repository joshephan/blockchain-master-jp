// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyAmm} from "../src/ToyAmm.sol";
import {ToyRangePool} from "../src/ToyRangePool.sol";
import {ToyToken} from "../src/ToyErc20.sol";

// 第196講の作成者確認用(デモのコピーにのみ)。全区間プールが区間0.81~1.21で実際に使う量、同じ深さの全区間プール
contract Extra196Test is Test {
    function _pool(uint256 amt) internal returns (ToyAmm p, ToyToken a, ToyToken b) {
        a = new ToyToken(18);
        b = new ToyToken(18);
        p = new ToyAmm(a, b, 0);
        a.mint(address(this), amt * 2);
        b.mint(address(this), amt * 2);
        a.approve(address(p), type(uint256).max);
        b.approve(address(p), type(uint256).max);
        p.addLiquidity(amt, amt);
    }

    // 1000/1000のプール: 価格1 → 1.21までに抜けるA、1 → 0.81までに抜けるB
    function test_fullRangeUsedShare() public {
        (ToyAmm p,, ToyToken b) = _pool(1000 ether);
        uint256 outA = p.swap(address(b), 100 ether, 0);
        console.log("B 100 in, A out", outA);
        console.log("price", p.spotPrice());

        (ToyAmm q, ToyToken a2,) = _pool(1000 ether);
        uint256 outB = q.swap(address(a2), 111_111_111_111_111_111_112, 0);
        console.log("A 111.11 in, B out", outB);
        console.log("price", q.spotPrice());
    }

    // 同じ深さ(L = 10000)を全区間に: 10000/10000のプールにB 100を入れるとA 99.0…
    function test_sameDepthFullRange() public {
        (ToyAmm p,, ToyToken b) = _pool(10_000 ether);
        uint256 outA = p.swap(address(b), 100 ether, 0);
        console.log("10000/10000 pool, B 100 in, A out", outA);
        console.log("price", p.spotPrice());
    }

    // 区間の端(A 0、B 2000)でAを入れて価格を区間の中に戻すと、また取引に使われる
    function test_reenterRange() public {
        ToyRangePool range = new ToyRangePool(10_000 ether, 0.9e18, 1.1e18, 1e18);
        range.swap1For0(1000 ether);
        uint256 outB = range.swap0For1(100 ether);
        (uint256 x, uint256 y) = range.amounts();
        console.log("A 100 in at edge, B out", outB);
        console.log("A, B after", x, y);
        console.log("price after", range.price());
    }

    // 区間の下端(価格0.81)に置いた同じポジション: B 0、Aだけが残る
    function test_lowerEdgeAllA() public {
        ToyRangePool range = new ToyRangePool(10_000 ether, 0.9e18, 1.1e18, 0.9e18);
        (uint256 x, uint256 y) = range.amounts();
        console.log("at 0.81, A, B", x, y);
    }
}
