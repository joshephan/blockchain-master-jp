// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {IMarket} from "../src/IMarket.sol";

// 信頼の前提のテスト。テスト名の頭の番号がdesign/architecture.md 6節の信頼の前提の番号
// Marketの外に置いたものが止まったり遅れたりしたとき、Marketがドキュメントに書いたとおりに動くかを見る
contract TrustTest is Base {
    function setUp() public {
        _deploy(0);
        _openPosition();
    }

    // T-01: COLの価格の出どころが止まると、COL担保アカウントの借り入れ・担保の引き出し・清算・借金の消去が止まり、返済はできる
    // 担保でない引き出し(bob USD)もできる
    function test_T01_feedStoppedRepayStillWorks() public {
        colFeed.stop();
        vm.startPrank(alice);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.borrow(address(usd), 1e6);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.withdraw(address(col), 1e18);
        market.repay(address(usd), 100e6);
        vm.stopPrank();
        vm.prank(carol);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.liquidate(alice, address(usd), address(col), 1e6);
        vm.expectRevert(TwapFeed.Stopped.selector);
        market.writeOffBadDebt(alice, address(usd));
        vm.prank(bob);
        market.withdraw(address(usd), 300e6);
        assertEq(market.debtOf(address(usd), alice), 600e6);
    }

    // T-01・F-09: 価格が1.0から0.3に一気に下がっても30分平均はゆっくり追いつく
    // 分ごとに平均価格・清算ライン・清算したら100返して受け取るCOLとそのCOLの今の値(0.3)を記録
    function test_T01_twapLagsRealDrop() public {
        colFeed.setPrice(0.3e18);
        uint256 t0 = vm.getBlockTimestamp();
        uint256[7] memory mins = [uint256(0), 5, 6, 10, 15, 20, 30];
        for (uint256 i = 0; i < mins.length; i++) {
            vm.warp(t0 + mins[i] * 60);
            uint256 p = market.priceOf(address(col));
            uint256 limit = market.liquidationLimit(alice);
            emit log_named_uint("minute", mins[i]);
            emit log_named_decimal_uint("  price", p, 18);
            emit log_named_decimal_uint("  liquidation line", limit, 18);
            if (limit < 700e18) {
                // 100返すと受け取るCOL = 100 × 1.05 ÷ 平均価格。そのCOLを今の価格0.3で売った値
                uint256 seize = uint256(105e18) * 1e18 / p;
                emit log_named_decimal_uint("  seize per 100 repaid", seize, 18);
                emit log_named_decimal_uint("  worth at 0.3", seize * 3 / 10, 18);
            }
        }
        assertEq(market.priceOf(address(col)), 0.3e18);
        assertEq(market.liquidationLimit(alice), 240e18);
    }

    // T-03: 利息はブロックの時刻でだけ積まれる。同じブロック内では何回呼んでも借金はそのまま、1秒後に上がる
    function test_T03_sameBlockSameIndex() public {
        _deploy(0.05e18);
        _openPosition();
        uint256 d0 = market.debtOf(address(usd), alice);
        vm.startPrank(alice);
        market.repay(address(usd), 1e6);
        market.borrow(address(usd), 1e6);
        vm.stopPrank();
        assertEq(market.debtOf(address(usd), alice), d0);
        vm.warp(vm.getBlockTimestamp() + 1);
        uint256 d1 = market.debtOf(address(usd), alice);
        assertGt(d1, d0);
        emit log_named_uint("debt after 1 second", d1);
    }
}
