// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Vm} from "forge-std/Vm.sol";
import {Base} from "./helpers/Base.sol";
import {IMarket} from "../src/IMarket.sol";

// O-01のログで数え直す。借りた人がいる順番(預け入れ・借り入れ・返済・引き出し・清算・借金の消去)を通りながら
// MarketのログだけでUSDの預け入れの合計・借り入れの合計を数え直し、状態変数と比べる
// 利息はログにない: 利率0なら同じ、利率があれば積み上がった利息の分だけずれる
contract RebuildTest is Base {
    int256 dep;
    int256 bor;

    function _scenario() internal {
        vm.recordLogs();
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.prank(dave);
        market.deposit(address(usd), 500e6);
        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 700e6);
        vm.stopPrank();
        vm.warp(vm.getBlockTimestamp() + 30 days);
        vm.prank(alice);
        market.repay(address(usd), 100e6);
        vm.prank(bob);
        market.withdraw(address(usd), 200e6);
        _price(0.3e18);
        uint256 debt = market.debtOf(address(usd), alice);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), debt);
        market.writeOffBadDebt(alice, address(usd));
        _replay(vm.getRecordedLogs());
    }

    function _replay(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory l = logs[i];
            if (l.emitter != address(market)) continue;
            bytes32 k = l.topics[0];
            if (k == IMarket.Liquidated.selector) {
                (address debtAsset, uint256 repaid,) = abi.decode(l.data, (address, uint256, uint256));
                if (debtAsset == address(usd)) bor -= int256(repaid);
                continue;
            }
            if (address(uint160(uint256(l.topics[1]))) != address(usd)) continue;
            if (k == IMarket.Deposited.selector) dep += int256(abi.decode(l.data, (uint256)));
            if (k == IMarket.Withdrawn.selector) dep -= int256(abi.decode(l.data, (uint256)));
            if (k == IMarket.Borrowed.selector) bor += int256(abi.decode(l.data, (uint256)));
            if (k == IMarket.Repaid.selector) bor -= int256(abi.decode(l.data, (uint256)));
            if (k == IMarket.BadDebtWrittenOff.selector) {
                uint256 loss = abi.decode(l.data, (uint256));
                bor -= int256(loss);
                dep -= int256(loss);
            }
        }
    }

    // 利率0: ログで数えた預け入れの合計と状態の預け入れの合計が丸めの数単位以内、借り入れの合計は0で同じ
    function test_O01_logsRebuildTotalsNoInterest() public {
        _deploy(0);
        _scenario();
        emit log_named_int("deposits from logs", dep);
        emit log_named_uint("deposits from state", market.totalDeposits(address(usd)));
        emit log_named_int("borrows from logs", bor);
        emit log_named_uint("borrows from state", market.totalBorrows(address(usd)));
        assertEq(bor, int256(market.totalBorrows(address(usd))));
        assertApproxEqAbs(uint256(dep), market.totalDeposits(address(usd)), 2);
    }

    // 折れ点5%: ログに利息がないので30日30分のあいだに積み上がった利息の分だけずれる
    function test_O01_logsMissInterest() public {
        _deploy(0.05e18);
        _scenario();
        emit log_named_int("deposits from logs", dep);
        emit log_named_uint("deposits from state", market.totalDeposits(address(usd)));
        assertGt(market.totalDeposits(address(usd)), uint256(dep));
    }
}
