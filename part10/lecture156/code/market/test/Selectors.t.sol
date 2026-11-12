// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// 第101講(第103講でsetStatusを追加): インターフェースに書いたセレクターとMarketのセレクターが一つ残らず同じか
// 第115講: MarketがIMarketを継承するので、形の照合はビルドが行う。このテストは手で書いたシグネチャと照合
contract SelectorsTest is Test {
    function test_selectorsMatch() public view {
        // ゲッターと親から継承した関数は型名では取り出せない(Error 9582)。インスタンスmで取り出す
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
    // 第115講: 宣言がIMarketの一か所なので、手で書いたシグネチャと照合
    function test_eventTopicsMatch() public pure {
        assertEq(IMarket.AssetAdded.selector, keccak256("AssetAdded(address,uint8)"));
        assertEq(IMarket.StatusChanged.selector, keccak256("StatusChanged(uint8,uint8)"));
        assertEq(IMarket.Deposited.selector, keccak256("Deposited(address,address,uint256)"));
        assertEq(IMarket.Withdrawn.selector, keccak256("Withdrawn(address,address,uint256)"));
    }

    // 第108講: エラーもセレクターが同じでなければ、呼ぶ側がIMarketの宣言でMarketの巻き戻りデータに名前を付けられない
    // 第115講: 宣言がIMarketの一か所なので、手で書いたシグネチャと照合
    function test_errorSelectorsMatch() public pure {
        assertEq(IMarket.InsufficientDeposit.selector, bytes4(keccak256("InsufficientDeposit(uint256,uint256)")));
        assertEq(IMarket.ZeroAdmin.selector, bytes4(keccak256("ZeroAdmin()")));
        assertEq(IMarket.NotAdmin.selector, bytes4(keccak256("NotAdmin(address)")));
        assertEq(IMarket.MarketFrozen.selector, bytes4(keccak256("MarketFrozen()")));
        assertEq(IMarket.NotActive.selector, bytes4(keccak256("NotActive(uint8)"))); // enumはuint8としてハッシュ
        assertEq(IMarket.ZeroAsset.selector, bytes4(keccak256("ZeroAsset()")));
        assertEq(IMarket.AlreadyListed.selector, bytes4(keccak256("AlreadyListed(address)")));
        assertEq(IMarket.RatioAboveCap.selector, bytes4(keccak256("RatioAboveCap(uint8,uint8)")));
        assertEq(IMarket.NotListed.selector, bytes4(keccak256("NotListed(address)")));
        assertEq(IMarket.ZeroAmount.selector, bytes4(keccak256("ZeroAmount()")));
        assertEq(IMarket.TransferFromFailed.selector, bytes4(keccak256("TransferFromFailed(address)")));
        assertEq(IMarket.TransferFailed.selector, bytes4(keccak256("TransferFailed(address)")));
    }

    function test_withdrawSelectorByHand() public pure {
        assertEq(IMarket.withdraw.selector, bytes4(keccak256("withdraw(address,uint256)")));
        assertEq(IMarket.addAsset.selector, bytes4(keccak256("addAsset(address,uint8)")));
    }
}
