// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ToyPool} from "../src/Mev172.sol";

contract Mev172Test is Test {
    function _fresh() internal returns (ToyPool) {
        return new ToyPool(1000, 1000);
    }

    // 割り込む取引がないときに受け取るB
    function _fairOut() internal returns (uint256) {
        ToyPool p = _fresh();
        return p.quoteAForB(100);
    }

    // スリッページの上限をかけると、割り込まれた瞬間に巻き戻る
    function test_minOutBlocksSandwich() public {
        uint256 fair = _fairOut();
        uint256 minOut = fair * 99 / 100;

        ToyPool p = _fresh();
        p.swapAForB(500); // 攻撃者が前で揺さぶる
        vm.expectRevert(abi.encodeWithSelector(ToyPool.Slippage.selector, p.quoteAForB(100), minOut));
        p.swapAForBMin(100, minOut);
    }

    // 割り込まなければ上限内でそのまま約定
    function test_minOutPassesWhenFair() public {
        uint256 fair = _fairOut();
        ToyPool p = _fresh();
        uint256 got = p.swapAForBMin(100, fair * 99 / 100);
        assertEq(got, fair);
    }
}
