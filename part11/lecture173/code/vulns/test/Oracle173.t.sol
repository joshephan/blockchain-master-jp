// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ToyPool} from "../src/Mev172.sol";
import {SpotOracle, TwapOracle, ToyLender} from "../src/Oracle173.sol";

contract Oracle173Test is Test {
    // 時間加重平均は一ブロックの揺さぶりではほとんど動かない
    function test_twapResistsOneBlock() public {
        ToyPool p = new ToyPool(1000, 1000);
        vm.warp(1_000_000);
        TwapOracle tw = new TwapOracle(p);
        uint256 startCum = tw.priceCumulative();
        uint256 startTs = vm.getBlockTimestamp();

        // 正常な区間1000秒
        vm.warp(vm.getBlockTimestamp() + 1000);
        tw.update();

        // 攻撃者が価格を揺さぶったブロック(1秒)
        p.swapBForA(3000);
        uint256 spotNow = p.reserveB() * 1e18 / p.reserveA();
        vm.warp(vm.getBlockTimestamp() + 1);
        tw.update();

        uint256 twap = tw.consult(startCum, startTs);
        emit log_named_uint("spotNow", spotNow);
        emit log_named_uint("twap", twap);
        assertGt(spotNow, 3e18); // スポットの値は大きく揺れたのに
        assertApproxEqRel(twap, 1e18, 0.01e18); // 平均は1.0付近(1%以内)
    }
}
