// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, AssetRegistry, Ledger, MarketBase, IERC20, Ratio, Rate} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第105講: 状態を変える関数が処理を終えた後にイベントを出すか。expectEmitは次の呼び出しがこのログを出すかを確認(第29講)
contract EventsTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function test_addAssetEmits() public {
        vm.expectEmit(address(market));
        emit AssetRegistry.AssetAdded(address(token), Ratio.wrap(75));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    function test_setStatusEmits() public {
        vm.expectEmit(address(market));
        emit MarketBase.StatusChanged(MarketBase.MarketStatus.Active, MarketBase.MarketStatus.Frozen);
        market.setStatus(MarketBase.MarketStatus.Frozen);
    }

    // withdrawAllは別に出力しない。内部で呼ぶwithdrawがWithdrawnを出力する
    function test_depositWithdrawAllEmit() public {
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        vm.expectEmit(address(market));
        emit Ledger.Deposited(address(token), address(this), 100);
        market.deposit(address(token), 100);
        vm.expectEmit(address(market));
        emit Ledger.Withdrawn(address(token), address(this), 100);
        market.withdrawAll(address(token));
    }
}
