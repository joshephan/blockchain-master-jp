// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// O-01のイベント引数のテスト。インデクサー・監視が読む値(トピックとデータ)が帳簿に書かれた値と同じかを、イベント11個ごとに見る
// OpsTestは呼び出しごとにログ一つと最初のトピックだけを見る
contract EventsTest is Base {
    function setUp() public {
        _deploy(0);
    }

    function test_O01_eventArgs() public {
        vm.expectEmit();
        emit IMarket.GuardianSet(bob);
        new Market(address(this), bob, 0);

        StdToken t = new StdToken("T", "T", 18);
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        vm.expectEmit(address(market));
        emit IMarket.AssetListed(address(t), address(f), 50, 123);
        market.listAsset(address(t), f, 50, 123);

        vm.expectEmit(address(market));
        emit IMarket.SupplyCapSet(address(usd), 5000e6);
        market.setSupplyCap(address(usd), 5000e6);

        vm.expectEmit(address(market));
        emit IMarket.PauseSet(address(usd), 3);
        market.pause(address(usd), 3);
        vm.expectEmit(address(market));
        emit IMarket.PauseSet(address(usd), 0);
        market.unpause(address(usd), 3);

        vm.expectEmit(address(market));
        emit IMarket.GuardianSet(carol);
        market.setGuardian(carol);

        vm.expectEmit(address(market));
        emit IMarket.Deposited(address(usd), bob, 1000e6);
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);

        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        vm.expectEmit(address(market));
        emit IMarket.CollateralSet(address(col), alice, true);
        market.setCollateral(address(col), true);
        vm.expectEmit(address(market));
        emit IMarket.Borrowed(address(usd), alice, 700e6);
        market.borrow(address(usd), 700e6);
        vm.expectEmit(address(market));
        emit IMarket.Repaid(address(usd), alice, 1e6);
        market.repay(address(usd), 1e6);
        vm.stopPrank();

        vm.expectEmit(address(market));
        emit IMarket.Withdrawn(address(usd), bob, 1e6);
        vm.prank(bob);
        market.withdraw(address(usd), 1e6);

        // 0.3で借金699を全部返すと、受け取る担保が預けた1000より多いので1000に減り、返した量も285.714286に減って記録される
        _price(0.3e18);
        vm.expectEmit(address(market));
        emit IMarket.Liquidated(alice, carol, address(col), address(usd), 285_714_286, 1000e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 699e6);

        vm.expectEmit(address(market));
        emit IMarket.BadDebtWrittenOff(address(usd), alice, 413_285_714);
        market.writeOffBadDebt(alice, address(usd));
    }

    // 借金より多く払うとRepaidに記録される量は借金(払うと言った量ではない)
    function test_O01_repaidIsPaidAmount() public {
        _openPosition();
        vm.expectEmit(address(market));
        emit IMarket.Repaid(address(usd), alice, 700e6);
        vm.prank(alice);
        market.repay(address(usd), type(uint256).max);
    }
}
