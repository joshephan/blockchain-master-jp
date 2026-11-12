// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyAmm} from "../src/ToyAmm.sol";
import {ToyToken} from "../src/ToyErc20.sol";

// 第195講のインパーマネントロス。外の価格はテストが決める数字(A一個 = B何個)
contract Il195Test is Test {
    ToyToken a;
    ToyToken b;
    address lp = address(0x11);
    address arb = address(0x33);

    function setUp() public {
        a = new ToyToken(18);
        b = new ToyToken(18);
    }

    function _pool(uint256 feeBps) internal returns (ToyAmm p) {
        p = new ToyAmm(a, b, feeBps);
        a.mint(lp, 1000 ether);
        b.mint(lp, 1000 ether);
        vm.startPrank(lp);
        a.approve(address(p), 1000 ether);
        b.approve(address(p), 1000 ether);
        p.addLiquidity(1000 ether, 1000 ether);
        vm.stopPrank();
    }

    function _swap(ToyAmm p, ToyToken t, uint256 amountIn) internal returns (uint256 out) {
        t.mint(arb, amountIn);
        vm.startPrank(arb);
        t.approve(address(p), amountIn);
        out = p.swap(address(t), amountIn, 0);
        vm.stopPrank();
    }

    // 外の価格が1 → 4に上がる。裁定取引がB 1000を入れてA 500を抜いていく(プールの価格4)
    // LPが引き出すとA 500 + B 2000 = B 4000相当、持っているだけならA 1000 + B 1000 = B 5000相当
    function test_impermanentLoss() public {
        ToyAmm p = _pool(0);
        uint256 outA = _swap(p, b, 1000 ether);
        console.log("arb got A", outA);
        console.log("pool price", p.spotPrice());

        uint256 shares = p.balanceOf(lp);
        vm.prank(lp);
        (uint256 gotA, uint256 gotB) = p.removeLiquidity(shares);
        uint256 lpValue = gotA * 4 + gotB; // B単位
        uint256 holdValue = 1000 ether * 4 + 1000 ether;
        console.log("lp A", gotA);
        console.log("lp B", gotB);
        console.log("lp value in B", lpValue);
        console.log("hold value in B", holdValue);
        // 裁定取引の取り分: A 500を外で4で売るとB 2000、入れたB 1000 → +1000
        uint256 arbProfit = outA * 4 - 1000 ether;
        console.log("arb profit in B", arbProfit);
        assertEq(lpValue, 4000 ether);
        assertEq(holdValue - lpValue, arbProfit);
    }

    // 価格が最初(1)に戻ると損失も消える
    function test_lossVanishesWhenPriceReturns() public {
        ToyAmm p = _pool(0);
        uint256 outA = _swap(p, b, 1000 ether);
        uint256 backB = _swap(p, a, outA);
        console.log("back B", backB);
        console.log("reserves", p.reserve0(), p.reserve1());
        uint256 shares = p.balanceOf(lp);
        vm.prank(lp);
        (uint256 gotA, uint256 gotB) = p.removeLiquidity(shares);
        console.log("lp gets", gotA, gotB);
        assertEq(gotA, 1000 ether);
        assertEq(gotB, 1000 ether);
    }

    // 価格変化ごとの損失(手数料0): 外の価格rに合わせてプールを動かした後のLPの価値 / 持っているだけの価値
    // 理論値 2√r / (1 + r): r = 1.21 → 0.995…、2 → 0.942…、4 → 0.8、9 → 0.6
    function test_lossTable() public {
        uint256[4] memory addB = [uint256(100 ether), 414213562373095048801, 1000 ether, 2000 ether];
        uint256[4] memory rNum = [uint256(121), 200, 400, 900];
        for (uint256 i = 0; i < 4; i++) {
            ToyAmm p = _pool(0);
            _swap(p, b, addB[i]);
            uint256 r = rNum[i]; // 外の価格 × 100
            uint256 lpValue = p.reserve0() * r / 100 + p.reserve1();
            uint256 holdValue = 1000 ether * r / 100 + 1000 ether;
            console.log(r, p.spotPrice(), lpValue * 1e6 / holdValue);
        }
    }

    // 手数料0.3%のプールで同じ価格を行き来する取引が続くと、kが大きくなりLPの取り分が増える
    function test_feesGrowK() public {
        ToyAmm p = _pool(30);
        uint256 k0 = p.reserve0() * p.reserve1();
        for (uint256 i = 0; i < 50; i++) {
            uint256 outB = _swap(p, a, 100 ether);
            _swap(p, b, outB);
        }
        uint256 k1 = p.reserve0() * p.reserve1();
        console.log("reserves after 50 round trips", p.reserve0(), p.reserve1());
        console.log("k grow x1e6", k1 * 1e6 / k0);
        uint256 shares = p.balanceOf(lp);
        vm.prank(lp);
        (uint256 gotA, uint256 gotB) = p.removeLiquidity(shares);
        console.log("lp gets", gotA, gotB);
        assertGt(k1, k0);
    }

    // 手数料が損失を埋めるかは取引量と価格変化しだい: 1 → 4の移動 + 往復50回の後
    function test_feesVersusLoss() public {
        ToyAmm p = _pool(30);
        for (uint256 i = 0; i < 50; i++) {
            uint256 outB = _swap(p, a, 100 ether);
            _swap(p, b, outB);
        }
        // プールの価格を外の価格4の近くへ動かす裁定取引
        _swap(p, b, 1000 ether);
        console.log("pool price", p.spotPrice());
        uint256 shares = p.balanceOf(lp);
        vm.prank(lp);
        (uint256 gotA, uint256 gotB) = p.removeLiquidity(shares);
        uint256 lpValue = gotA * 4 + gotB;
        console.log("lp A, B", gotA, gotB);
        console.log("lp value / hold x1e6", lpValue * 1e6 / 5000 ether);
    }
}
