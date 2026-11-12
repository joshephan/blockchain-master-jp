// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, AssetRegistry, Ledger, MarketBase, InsufficientDeposit, ZeroAdmin, NotAdmin, MarketFrozen, NotActive, ZeroAsset, AlreadyListed,
    RatioAboveCap, NotListed, ZeroAmount, TransferFromFailed, TransferFailed} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// 第101講(第103講でsetStatusを追加): インターフェースに書いたセレクターとMarketのセレクターが一つ残らず同じか
contract SelectorsTest is Test {
    function test_selectorsMatch() public view {
        // ゲッターはMarket.status.selectorのように型名では取り出せない(Error 9582)。インスタンスmでm.status.selectorのように取り出す
        Market m = Market(address(0));
        assertEq(IMarket.addAsset.selector, m.addAsset.selector);
        assertEq(IMarket.deposit.selector, m.deposit.selector);
        assertEq(IMarket.withdraw.selector, m.withdraw.selector);
        assertEq(IMarket.withdrawAll.selector, m.withdrawAll.selector);
        assertEq(IMarket.setStatus.selector, m.setStatus.selector); // 第103講
        assertEq(IMarket.assetCount.selector, m.assetCount.selector);
        assertEq(IMarket.interestFor.selector, Market.interestFor.selector);
        assertEq(IMarket.elapsedOf.selector, m.elapsedOf.selector);
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

    // 第107講: イベントもtopic0が同じでなければ、読む側がIMarketの規格でMarketのログを読めない
    function test_eventTopicsMatch() public pure {
        assertEq(IMarket.AssetAdded.selector, AssetRegistry.AssetAdded.selector);
        assertEq(IMarket.StatusChanged.selector, MarketBase.StatusChanged.selector);
        assertEq(IMarket.Deposited.selector, Ledger.Deposited.selector);
        assertEq(IMarket.Withdrawn.selector, Ledger.Withdrawn.selector);
    }

    // 第108講: エラーもセレクターが同じでなければ、呼ぶ側がIMarketの宣言でMarketの巻き戻りデータに名前を付けられない
    function test_errorSelectorsMatch() public pure {
        assertEq(IMarket.InsufficientDeposit.selector, InsufficientDeposit.selector);
        assertEq(IMarket.ZeroAdmin.selector, ZeroAdmin.selector);
        assertEq(IMarket.NotAdmin.selector, NotAdmin.selector);
        assertEq(IMarket.MarketFrozen.selector, MarketFrozen.selector);
        assertEq(IMarket.NotActive.selector, NotActive.selector);
        assertEq(IMarket.ZeroAsset.selector, ZeroAsset.selector);
        assertEq(IMarket.AlreadyListed.selector, AlreadyListed.selector);
        assertEq(IMarket.RatioAboveCap.selector, RatioAboveCap.selector);
        assertEq(IMarket.NotListed.selector, NotListed.selector);
        assertEq(IMarket.ZeroAmount.selector, ZeroAmount.selector);
        assertEq(IMarket.TransferFromFailed.selector, TransferFromFailed.selector);
        assertEq(IMarket.TransferFailed.selector, TransferFailed.selector);
        assertEq(NotActive.selector, bytes4(keccak256("NotActive(uint8)"))); // enumはuint8としてハッシュ
    }

    function test_withdrawSelectorByHand() public pure {
        assertEq(Ledger.withdraw.selector, bytes4(keccak256("withdraw(address,uint256)")));
        assertEq(AssetRegistry.addAsset.selector, bytes4(keccak256("addAsset(address,uint8)")));
    }
}
