// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyAmm} from "../src/ToyAmm.sol";
import {ToyToken, FeeToken} from "../src/ToyErc20.sol";

contract Amm194Test is Test {
    ToyToken a;
    ToyToken b;
    ToyAmm pool;
    address lp = address(0x11);
    address trader = address(0x22);

    function setUp() public {
        a = new ToyToken(18);
        b = new ToyToken(18);
        pool = new ToyAmm(a, b, 30);
        _seed(pool, a, b, 1000 ether, 1000 ether);
    }

    function _seed(ToyAmm p, ToyToken t0, ToyToken t1, uint256 x, uint256 y) internal {
        t0.mint(lp, x);
        t1.mint(lp, y);
        vm.startPrank(lp);
        t0.approve(address(p), x);
        t1.approve(address(p), y);
        p.addLiquidity(x, y);
        vm.stopPrank();
    }

    function _swapA(uint256 amountIn, uint256 minOut) internal returns (uint256) {
        a.mint(trader, amountIn);
        vm.startPrank(trader);
        a.approve(address(pool), amountIn);
        uint256 out = pool.swap(address(a), amountIn, minOut);
        vm.stopPrank();
        return out;
    }

    // 1000/1000のプールにA 100: 手数料0.3%ならB 90.66…、積kは増える
    function test_swapWithFee() public {
        uint256 k0 = pool.reserve0() * pool.reserve1();
        uint256 out = _swapA(100 ether, 0);
        uint256 k1 = pool.reserve0() * pool.reserve1();
        console.log("out", out);
        console.log("k0", k0);
        console.log("k1", k1);
        console.log("spot after", pool.spotPrice());
        assertGt(k1, k0);
    }

    // 手数料のない同じプールなら90.909…
    function test_swapNoFee() public {
        ToyAmm p0 = new ToyAmm(a, b, 0);
        _seed(p0, a, b, 1000 ether, 1000 ether);
        console.log("no fee out", p0.quote(address(a), 100 ether));
    }

    // 入れる量によって受け取る値(価格影響)。1、10、100、500、1000
    function test_priceImpactTable() public view {
        uint256[5] memory ins = [uint256(1 ether), 10 ether, 100 ether, 500 ether, 1000 ether];
        for (uint256 i = 0; i < 5; i++) {
            uint256 out = pool.quote(address(a), ins[i]);
            console.log(ins[i] / 1 ether, out, out * 1e18 / ins[i]);
        }
    }

    // 1 weiを入れると0を受け取る(割り算が切り捨てる)
    function test_dustGetsZero() public view {
        assertEq(pool.quote(address(a), 1), 0);
        console.log("1 wei ->", pool.quote(address(a), 1));
        console.log("1000 wei ->", pool.quote(address(a), 1000));
    }

    // 受け取る量は切り捨て、入れる量は切り上げ: 切り上げで求めた量を入れると欲しい量以上を受け取る
    function test_roundingFavorsPool() public view {
        uint256 want = 90 ether;
        uint256 need = pool.getAmountIn(want, pool.reserve0(), pool.reserve1());
        uint256 got = pool.getAmountOut(need, pool.reserve0(), pool.reserve1());
        uint256 gotLess = pool.getAmountOut(need - 1, pool.reserve0(), pool.reserve1());
        console.log("need", need);
        console.log("got", got);
        console.log("got with need-1", gotLess);
        assertGe(got, want);
        assertLt(gotLess, want);
    }

    // 受け取る最小量: 91を要求するとSlippage(90.66…, 91)
    function test_minOutReverts() public {
        a.mint(trader, 100 ether);
        vm.startPrank(trader);
        a.approve(address(pool), 100 ether);
        vm.expectRevert(abi.encodeWithSelector(ToyAmm.Slippage.selector, 90661089388014913158, 91 ether));
        pool.swap(address(a), 100 ether, 91 ether);
        vm.stopPrank();
    }

    // 割り算を先にすると価格が整数に切り詰められる: 1000 A / 1500 B
    function test_spotDivideFirst() public {
        ToyAmm p = new ToyAmm(a, b, 30);
        _seed(p, a, b, 1000 ether, 1500 ether);
        uint256 mulFirst = p.reserve1() * 1e18 / p.reserve0();
        uint256 divFirst = p.reserve1() / p.reserve0() * 1e18;
        console.log("mul first", mulFirst);
        console.log("div first", divFirst);
        assertEq(mulFirst, 1.5e18);
        assertEq(divFirst, 1e18);
    }

    // 桁数の違う二つのトークン(18桁のA、6桁のU): 残高の比率のままだと10の12乗倍ずれる
    function test_decimalsSkewPrice() public {
        ToyToken u = new ToyToken(6);
        ToyAmm p = new ToyAmm(a, u, 30);
        _seed(p, a, u, 1000 ether, 1000e6);
        uint256 raw = p.spotPrice();
        uint256 fixedPrice = raw * 10 ** (a.decimals() - u.decimals());
        console.log("raw", raw);
        console.log("adjusted", fixedPrice);
        assertEq(raw, 1e6);
        assertEq(fixedPrice, 1e18);
    }

    // 手数料トークン: プールは残高の差で数えるので、実際に入ってきた99だけを入れたものとして扱う
    function test_feeTokenCountedByBalance() public {
        FeeToken f = new FeeToken();
        ToyAmm p = new ToyAmm(f, b, 30);
        f.mint(lp, 1000 ether);
        b.mint(lp, 1000 ether);
        vm.startPrank(lp);
        f.approve(address(p), 1000 ether);
        b.approve(address(p), 1000 ether);
        p.addLiquidity(1000 ether, 1000 ether);
        vm.stopPrank();
        console.log("reserve0 after add", p.reserve0());

        f.mint(trader, 100 ether);
        vm.startPrank(trader);
        f.approve(address(p), 100 ether);
        uint256 out = p.swap(address(f), 100 ether, 0);
        vm.stopPrank();
        console.log("out for 100 sent", out);
        console.log("quote for 99", p.getAmountOut(99 ether, 990 ether, 1000 ether));
        assertEq(p.reserve0(), 990 ether + 99 ether);
        assertEq(f.balanceOf(address(p)), p.reserve0());
    }

    // 任意の量を入れて受け取ったものをすぐ入れ戻しても、最初より多くはならない
    function testFuzz_roundTripNeverProfits(uint256 amountIn) public {
        amountIn = bound(amountIn, 1, 10_000 ether);
        uint256 outB = _swapA(amountIn, 0);
        vm.assume(outB > 0);
        vm.startPrank(trader);
        b.approve(address(pool), outB);
        uint256 backA = pool.swap(address(b), outB, 0);
        vm.stopPrank();
        assertLe(backA, amountIn);
    }

    // 積kはどんな交換の後でも減らない
    function testFuzz_kNeverDecreases(uint256 amountIn) public {
        amountIn = bound(amountIn, 1, 10_000 ether);
        uint256 k0 = pool.reserve0() * pool.reserve1();
        a.mint(trader, amountIn);
        vm.startPrank(trader);
        a.approve(address(pool), amountIn);
        try pool.swap(address(a), amountIn, 0) {} catch {}
        vm.stopPrank();
        assertGe(pool.reserve0() * pool.reserve1(), k0);
    }
}
