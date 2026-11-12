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
        // 第197講: 借り入れ・価格の出どころの関数十三個
        assertEq(IMarket.setPriceFeed.selector, Market.setPriceFeed.selector);
        assertEq(IMarket.setCollateral.selector, Market.setCollateral.selector);
        assertEq(IMarket.borrow.selector, Market.borrow.selector);
        assertEq(IMarket.repay.selector, Market.repay.selector);
        assertEq(IMarket.depositOf.selector, m.depositOf.selector);
        assertEq(IMarket.debtOf.selector, m.debtOf.selector);
        assertEq(IMarket.utilization.selector, m.utilization.selector);
        assertEq(IMarket.borrowRate.selector, m.borrowRate.selector);
        assertEq(IMarket.priceOf.selector, Market.priceOf.selector);
        assertEq(IMarket.accountHealth.selector, Market.accountHealth.selector);
        assertEq(IMarket.reserves.selector, m.reserves.selector);
        assertEq(IMarket.priceConfig.selector, m.priceConfig.selector);
        assertEq(IMarket.TWAP_WINDOW.selector, m.TWAP_WINDOW.selector);
        // 第198講: 清算の関数五つ
        assertEq(IMarket.liquidate.selector, Market.liquidate.selector);
        assertEq(IMarket.liquidationLimit.selector, Market.liquidationLimit.selector);
        assertEq(IMarket.LIQUIDATION_GAP.selector, m.LIQUIDATION_GAP.selector);
        assertEq(IMarket.LIQUIDATION_BONUS.selector, m.LIQUIDATION_BONUS.selector);
        assertEq(IMarket.CLOSE_FACTOR.selector, m.CLOSE_FACTOR.selector);
        assertEq(IMarket.writeOffBadDebt.selector, Market.writeOffBadDebt.selector); // 第199講
    }

    // 第107講: イベントもtopic0が同じでなければ、読む側がIMarketの規格でMarketのログを読めない
    // 第115講: 宣言がIMarketの一か所なので、手で書いたシグネチャと照合
    function test_eventTopicsMatch() public pure {
        assertEq(IMarket.AssetAdded.selector, keccak256("AssetAdded(address,uint8)"));
        assertEq(IMarket.StatusChanged.selector, keccak256("StatusChanged(uint8,uint8)"));
        assertEq(IMarket.Deposited.selector, keccak256("Deposited(address,address,uint256)"));
        assertEq(IMarket.Withdrawn.selector, keccak256("Withdrawn(address,address,uint256)"));
        assertEq(IMarket.PriceFeedSet.selector, keccak256("PriceFeedSet(address,address)")); // 第197講
        assertEq(IMarket.CollateralSet.selector, keccak256("CollateralSet(address,address,bool)"));
        assertEq(IMarket.Borrowed.selector, keccak256("Borrowed(address,address,uint256)"));
        assertEq(IMarket.Repaid.selector, keccak256("Repaid(address,address,uint256)"));
        assertEq(IMarket.Liquidated.selector, keccak256("Liquidated(address,address,address,address,uint256,uint256)")); // 第198講
        assertEq(IMarket.BadDebtWrittenOff.selector, keccak256("BadDebtWrittenOff(address,address,uint256)")); // 第199講
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
        assertEq(IMarket.ZeroFeed.selector, bytes4(keccak256("ZeroFeed()"))); // 第197講
        assertEq(IMarket.PriceFeedAlreadySet.selector, bytes4(keccak256("PriceFeedAlreadySet(address)")));
        assertEq(IMarket.NoPriceFeed.selector, bytes4(keccak256("NoPriceFeed(address)")));
        assertEq(IMarket.InsufficientCollateral.selector, bytes4(keccak256("InsufficientCollateral(uint256,uint256)")));
        assertEq(IMarket.InsufficientLiquidity.selector, bytes4(keccak256("InsufficientLiquidity(uint256,uint256)")));
        assertEq(IMarket.NoDebt.selector, bytes4(keccak256("NoDebt(address)")));
        assertEq(IMarket.NotLiquidatable.selector, bytes4(keccak256("NotLiquidatable(uint256,uint256)"))); // 第198講
        assertEq(IMarket.NotCollateral.selector, bytes4(keccak256("NotCollateral(address)")));
        assertEq(IMarket.AboveCloseFactor.selector, bytes4(keccak256("AboveCloseFactor(uint256,uint256)")));
        assertEq(IMarket.HasCollateral.selector, bytes4(keccak256("HasCollateral(uint256)"))); // 第199講
    }

    function test_withdrawSelectorByHand() public pure {
        assertEq(IMarket.withdraw.selector, bytes4(keccak256("withdraw(address,uint256)")));
        assertEq(IMarket.addAsset.selector, bytes4(keccak256("addAsset(address,uint8)")));
    }
}
