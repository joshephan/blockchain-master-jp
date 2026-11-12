// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Vm} from "forge-std/Vm.sol";
import {Base} from "./helpers/Base.sol";
import {IMarket} from "../src/IMarket.sol";

// 運用の要件O-01~O-02。テスト名の頭の番号がdesign/requirements.mdの要件番号
contract OpsTest is Base {
    function setUp() public {
        _deploy(0);
    }

    // 状態を変える呼び出し一つにMarketのログ一つ、最初のトピックがその操作のイベント
    function test_O01_eventsForStateChanges() public {
        _expectOne(abi.encodeCall(IMarket.setSupplyCap, (address(usd), 5000e6)), IMarket.SupplyCapSet.selector);
        _expectOne(abi.encodeCall(IMarket.pause, (address(usd), 1)), IMarket.PauseSet.selector);
        _expectOne(abi.encodeCall(IMarket.unpause, (address(usd), 1)), IMarket.PauseSet.selector);
        vm.prank(bob);
        _expectOne(abi.encodeCall(IMarket.deposit, (address(usd), 1000e6)), IMarket.Deposited.selector);
        vm.prank(alice);
        _expectOne(abi.encodeCall(IMarket.deposit, (address(col), 1000e18)), IMarket.Deposited.selector);
        vm.prank(alice);
        _expectOne(abi.encodeCall(IMarket.setCollateral, (address(col), true)), IMarket.CollateralSet.selector);
        vm.prank(alice);
        _expectOne(abi.encodeCall(IMarket.borrow, (address(usd), 700e6)), IMarket.Borrowed.selector);
        vm.prank(alice);
        _expectOne(abi.encodeCall(IMarket.repay, (address(usd), 1e6)), IMarket.Repaid.selector);
        vm.prank(bob);
        _expectOne(abi.encodeCall(IMarket.withdraw, (address(usd), 1e6)), IMarket.Withdrawn.selector);
        _price(0.3e18);
        vm.prank(carol);
        _expectOne(
            abi.encodeCall(IMarket.liquidate, (alice, address(usd), address(col), 699e6)), IMarket.Liquidated.selector
        );
        _expectOne(abi.encodeCall(IMarket.writeOffBadDebt, (alice, address(usd))), IMarket.BadDebtWrittenOff.selector);
    }

    function _expectOne(bytes memory data, bytes32 topic) internal {
        vm.recordLogs();
        (bool ok,) = address(market).call(data);
        assertTrue(ok);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 n;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == address(market)) {
                n++;
                assertEq(logs[i].topics[0], topic);
            }
        }
        assertEq(n, 1);
    }

    // 監視・インデクサーのツールが呼ぶセレクター。前の版のMarketと同じシグネチャなのでセレクターが同じ
    function test_O02_monitorSelectors() public pure {
        assertEq(IMarket.totalDeposits.selector, bytes4(0xe9403256));
        assertEq(IMarket.assetCount.selector, bytes4(0xeafe7a74));
        assertEq(IMarket.deposit.selector, bytes4(keccak256("deposit(address,uint256)")));
        assertEq(IMarket.Deposited.selector, keccak256("Deposited(address,address,uint256)"));
        assertEq(IMarket.Liquidated.selector, keccak256("Liquidated(address,address,address,address,uint256,uint256)"));
    }
}
