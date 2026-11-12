// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// 第101講: インターフェースに書いたセレクターとMarketのセレクターが一つ残らず同じか
contract SelectorsTest is Test {
    function test_selectorsMatch() public view {
        // ゲッターはMarket.status.selectorのように型名では取り出せない(Error 9582)。インスタンスmでm.status.selectorのように取り出す
        Market m = Market(address(0));
        assertEq(IMarket.addAsset.selector, Market.addAsset.selector);
        assertEq(IMarket.deposit.selector, Market.deposit.selector);
        assertEq(IMarket.withdraw.selector, Market.withdraw.selector);
        assertEq(IMarket.withdrawAll.selector, Market.withdrawAll.selector);
        assertEq(IMarket.assetCount.selector, Market.assetCount.selector);
        assertEq(IMarket.interestFor.selector, Market.interestFor.selector);
        assertEq(IMarket.elapsedOf.selector, Market.elapsedOf.selector);
        assertEq(IMarket.collateralCount.selector, Market.collateralCount.selector);
        assertEq(IMarket.status.selector, m.status.selector);
        assertEq(IMarket.collateralRatio.selector, m.collateralRatio.selector);
        assertEq(IMarket.admin.selector, m.admin.selector);
        assertEq(IMarket.interestRate.selector, m.interestRate.selector);
        assertEq(IMarket.assets.selector, m.assets.selector);
        assertEq(IMarket.assetConfig.selector, m.assetConfig.selector);
        assertEq(IMarket.positions.selector, m.positions.selector);
        assertEq(IMarket.totalDeposits.selector, m.totalDeposits.selector);
        assertEq(IMarket.totalBorrows.selector, m.totalBorrows.selector);
        assertEq(IMarket.SECONDS_PER_YEAR.selector, m.SECONDS_PER_YEAR.selector);
    }

    function test_withdrawSelectorByHand() public pure {
        assertEq(Market.withdraw.selector, bytes4(keccak256("withdraw(address,uint256)")));
        assertEq(Market.addAsset.selector, bytes4(keccak256("addAsset(address,uint8)")));
    }
}
