// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// 第159講: MarketにはsupportsInterfaceがない。ERC-165の確認手順(最初の問い合わせ、ガス30,000)で失敗に終わるか、
// IMarketのインターフェースIDが関数セレクター19個のXORかを確認
// 第197講: 関数を十三個足して32個、インターフェースIDが0xab691738から0x93a1e693に変わる
// 第198講: 清算の関数五つを足して37個、インターフェースID 0x340612db
// 第199講: writeOffBadDebtを足して38個、インターフェースID 0x6edfb350
contract IntrospectionTest is Test {
    function test_noErc165() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        (bool ok, bytes memory data) =
            address(market).staticcall{gas: 30000}(abi.encodeWithSelector(bytes4(0x01ffc9a7), bytes4(0x01ffc9a7)));
        assertFalse(ok);
        assertEq(data.length, 0);
    }

    function test_iMarketInterfaceId() public pure {
        bytes4 x = IMarket.addAsset.selector ^ IMarket.deposit.selector ^ IMarket.withdraw.selector
            ^ IMarket.withdrawAll.selector ^ IMarket.setStatus.selector ^ IMarket.assetCount.selector
            ^ IMarket.interestFor.selector ^ IMarket.elapsedOf.selector ^ IMarket.collateralCount.selector
            ^ IMarket.status.selector ^ IMarket.collateralRatio.selector ^ IMarket.admin.selector
            ^ IMarket.interestRate.selector ^ IMarket.assets.selector ^ IMarket.assetConfig.selector
            ^ IMarket.positions.selector ^ IMarket.totalDeposits.selector ^ IMarket.totalBorrows.selector
            ^ IMarket.SECONDS_PER_YEAR.selector;
        x = x ^ IMarket.setPriceFeed.selector ^ IMarket.setCollateral.selector ^ IMarket.borrow.selector
            ^ IMarket.repay.selector ^ IMarket.depositOf.selector ^ IMarket.debtOf.selector
            ^ IMarket.utilization.selector ^ IMarket.borrowRate.selector ^ IMarket.priceOf.selector
            ^ IMarket.accountHealth.selector ^ IMarket.reserves.selector ^ IMarket.priceConfig.selector
            ^ IMarket.TWAP_WINDOW.selector;
        x = x ^ IMarket.liquidate.selector ^ IMarket.liquidationLimit.selector ^ IMarket.LIQUIDATION_GAP.selector
            ^ IMarket.LIQUIDATION_BONUS.selector ^ IMarket.CLOSE_FACTOR.selector;
        x = x ^ IMarket.writeOffBadDebt.selector;
        assertEq(type(IMarket).interfaceId, x);
        assertEq(x, bytes4(0x6edfb350));
    }
}
