// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SimpleToken, ToyOracle} from "../src/Toys.sol";
import {AlgoStable} from "../src/AlgoStable.sol";
import {VaultUSD} from "../src/VaultUSD.sol";

contract Algo201Test is Test {
    address alice = makeAddr("alice");
    address trader = makeAddr("trader");

    ToyOracle oracle;
    AlgoStable algo;
    SimpleToken ausd;
    SimpleToken vol;

    // 最初: VOL 6,000個をaliceが持つ、VOL 1個 = 10ドル
    // aliceがVOL 5,000個(5万ドル相当)をバーンしてAUSD 50,000を受け取る -> VOL 1,000個が残る
    function setUp() public {
        vm.roll(10);
        oracle = new ToyOracle(10e18);
        algo = new AlgoStable(oracle, alice, 6000e18);
        ausd = algo.ausd();
        vol = algo.vol();
        vm.roll(11);
        vm.prank(alice);
        algo.mintStable(5000e18);
    }

    function test_setup() public view {
        assertEq(ausd.totalSupply(), 50_000e18);
        assertEq(vol.totalSupply(), 1000e18);
        assertEq(ausd.balanceOf(address(algo)), 0); // 金庫に残るものなし
        assertEq(vol.balanceOf(address(algo)), 0);
    }

    // 1ドル未満: AUSD 100を外で98ドルで買ったとして償還すると10ドルのVOL 10個
    function test_belowPegRedeem() public {
        vm.prank(alice);
        ausd.transfer(trader, 100e18);
        vm.prank(trader);
        uint256 out = algo.redeemStable(100e18);
        assertEq(out, 10e18);
        assertEq(ausd.totalSupply(), 49_900e18);
        assertEq(vol.totalSupply(), 1010e18);
    }

    // 1ドル超: VOL 10個(100ドル相当)をバーンするとAUSD 100
    function test_abovePegMint() public {
        vm.prank(alice);
        vol.transfer(trader, 10e18);
        vm.prank(trader);
        uint256 out = algo.mintStable(10e18);
        assertEq(out, 100e18);
        assertEq(vol.totalSupply(), 990e18);
    }

    // 同じブロックで新しく書いた価格はそのブロックの発行・償還には使われない
    function test_sameBlockPriceNotUsed() public {
        vm.prank(alice);
        vol.transfer(trader, 20e18);
        vm.roll(12);
        oracle.update(20e18);
        vm.prank(trader);
        assertEq(algo.mintStable(10e18), 100e18); // 前のブロックの値10ドル
        vm.roll(13);
        vm.prank(trader);
        assertEq(algo.mintStable(10e18), 200e18); // 次のブロックから20ドル
    }

    // 償還が集中するとき。VOL全体に市場がつける値が1万ドルのままと仮定
    // 回ごとにAUSD 5,000を償還し、価格 = 1万ドル / VOLの供給量
    function test_spiralMarketValueFixed() public {
        _spiral(10_000e18, 100);
    }

    // 受け取ったVOLを売ったとき市場がつける値が回ごとに20%減るケース
    function test_spiralMarketValueFalling() public {
        _spiral(10_000e18, 80);
    }

    function _spiral(uint256 marketValue, uint256 keepPct) internal {
        uint256 startVol = vol.totalSupply();
        uint256 firstOut;
        vm.prank(alice);
        ausd.transfer(trader, 50_000e18);
        console.log("round | VOL minted | VOL supply | VOL price(1/10000 USD)");
        console.log(0, 0, startVol / 1e18, oracle.price() / 1e14);
        for (uint256 i = 1; i <= 10; i++) {
            vm.prank(trader);
            uint256 out = algo.redeemStable(5000e18);
            if (i == 1) firstOut = out;
            marketValue = marketValue * keepPct / 100;
            oracle.update(marketValue * 1e18 / vol.totalSupply());
            vm.roll(vm.getBlockNumber() + 1);
            console.log(i, out / 1e18, vol.totalSupply() / 1e18, oracle.price() / 1e14);
        }
        // 最初の回にAUSD 5,000を出して受け取ったVOLが最後の価格で何ドルか(セント)
        console.log("first round VOL", firstOut / 1e18, "now worth cents", firstOut * oracle.price() / 1e34);
        assertEq(ausd.totalSupply(), 0);
        assertGt(vol.totalSupply(), startVol * 50);
    }

    // 比較: 担保型は担保の値が下がっても担保トークンを新しく発行しない
    function test_vaultDoesNotMintCollateral() public {
        SimpleToken col = new SimpleToken("Collateral", address(this));
        ToyOracle o = new ToyOracle(1e18);
        VaultUSD vault = new VaultUSD(col, o);
        col.mint(alice, 150e18);
        vm.roll(vm.getBlockNumber() + 1);
        vm.startPrank(alice);
        col.approve(address(vault), 150e18);
        vault.deposit(150e18);
        vault.mint(100e18);
        vm.stopPrank();
        o.update(0.6e18);
        vm.roll(vm.getBlockNumber() + 1);
        assertEq(col.totalSupply(), 150e18);
        assertEq(col.balanceOf(address(vault)), 150e18);
        assertEq(vault.valueOf(alice), 90e18);
    }
}
