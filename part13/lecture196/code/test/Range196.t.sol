// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ToyRangePool} from "../src/ToyRangePool.sol";
import {ToyAmm} from "../src/ToyAmm.sol";
import {ToyToken} from "../src/ToyErc20.sol";

contract PlainMath {
    function mulThenDiv(uint256 a, uint256 b, uint256 d) external pure returns (uint256) {
        return a * b / d;
    }
}

// 第196講の集中流動性。価格1、区間0.81~1.21(√ 0.9~1.1)、L = 10000
contract Range196Test is Test {
    ToyRangePool range;
    ToyToken a;
    ToyToken b;
    ToyAmm full;

    function setUp() public {
        range = new ToyRangePool(10_000 ether, 0.9e18, 1.1e18, 1e18);
        a = new ToyToken(18);
        b = new ToyToken(18);
        full = new ToyAmm(a, b, 0);
        a.mint(address(this), 1000 ether);
        b.mint(address(this), 1000 ether);
        a.approve(address(full), 1000 ether);
        b.approve(address(full), 1000 ether);
        full.addLiquidity(1000 ether, 1000 ether);
    }

    // 区間プールに実際に入っている量: A 909.09…、B 1000
    function test_rangeAmounts() public view {
        (uint256 x, uint256 y) = range.amounts();
        console.log("range A", x);
        console.log("range B", y);
    }

    // 同じB 100を入れると: 区間プールはA 99.0…、全区間の1000/1000プールはA 90.9…
    function test_deeperInRange() public {
        uint256 outRange = range.swap1For0(100 ether);
        uint256 outFull = full.quote(address(b), 100 ether);
        console.log("range out", outRange);
        console.log("full out", outFull);
        console.log("range price after", range.price());
        assertGt(outRange, outFull);
    }

    // 逆方向: A 100を入れるとB 99.0…、区間の下端(√ 0.9)を超えるとOutOfRange
    function test_swapDown() public {
        uint256 out = range.swap0For1(100 ether);
        console.log("A 100 in, B out", out);
        console.log("price after", range.price());
        vm.expectRevert();
        range.swap0For1(2000 ether);
    }

    // 同じ深さ(L = 10000)を全区間に敷くにはA 10000 + B 10000が要る
    function test_capitalForSameDepth() public pure {
        console.log("full range needs", uint256(10_000 ether), uint256(10_000 ether));
    }

    // B 1000を入れると√価格が区間の端1.1に届き、Aが全部抜ける。少しでも多く入れるとOutOfRange
    function test_exitRange() public {
        uint256 out = range.swap1For0(1000 ether);
        (uint256 x, uint256 y) = range.amounts();
        console.log("out at edge", out);
        console.log("left A, B", x, y);
        console.log("price at edge", range.price());
        assertEq(x, 0);
        vm.expectRevert(abi.encodeWithSelector(ToyRangePool.OutOfRange.selector, 1.1e18 + 1, 0.9e18, 1.1e18));
        range.swap1For0(10_000); // 1万wei: √価格が1上がる
    }

    // 価格が1 → 1.21: 区間ポジション2000 / 持っているだけ2100(−4.76%)、全区間2200 / 2210(−0.45%)
    function test_lossAmplified() public {
        (uint256 x0, uint256 y0) = range.amounts();
        range.swap1For0(1000 ether);
        (uint256 x1, uint256 y1) = range.amounts();
        uint256 rangeLp = x1 * 121 / 100 + y1;
        uint256 rangeHold = x0 * 121 / 100 + y0;
        console.log("range lp / hold x1e6", rangeLp * 1e6 / rangeHold, rangeLp, rangeHold);

        b.mint(address(this), 100 ether);
        b.approve(address(full), 100 ether);
        full.swap(address(b), 100 ether, 0);
        uint256 fullLp = full.reserve0() * 121 / 100 + full.reserve1();
        uint256 fullHold = 1000 ether * 121 / 100 + 1000 ether;
        console.log("full lp / hold x1e6", fullLp * 1e6 / fullHold, fullLp, fullHold);
        console.log("full price", full.spotPrice());
    }

    // 積が256ビットを超える中間値: 普通のa * b / dはPanic 0x11、mulDivは2の150乗
    function test_mulDivFullPrecision() public {
        PlainMath m = new PlainMath();
        uint256 x = 2 ** 200;
        uint256 y = 2 ** 100;
        uint256 d = 2 ** 150;
        vm.expectRevert(stdError.arithmeticError);
        m.mulThenDiv(x, y, d);
        assertEq(Math.mulDiv(x, y, d), 2 ** 150);
    }

    // あふれない範囲ではmulDivは普通の計算と同じ答え(チェックのない行をテストで残す)
    function testFuzz_mulDivMatchesPlain(uint128 x, uint128 y, uint128 d) public pure {
        vm.assume(d > 0);
        assertEq(Math.mulDiv(x, y, d), uint256(x) * y / d);
    }

    // 切り上げを選ぶと、余りがあるときだけ1大きい
    function test_mulDivRounding() public pure {
        assertEq(Math.mulDiv(10, 1, 3), 3);
        assertEq(Math.mulDiv(10, 1, 3, Math.Rounding.Ceil), 4);
        assertEq(Math.mulDiv(9, 1, 3, Math.Rounding.Ceil), 3);
    }
}
