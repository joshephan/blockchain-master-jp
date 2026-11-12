// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第152講: 状態表をテストで。三つの状態ごとに状態を変える関数五つを呼び、表と同じ結果か、
// 同じ状態に変える呼び出し、範囲外の状態の値、合計の欄とアカウントの欄の和を確認
contract StatusTableTest is Test {
    MockToken token;
    MockToken other;
    Market market;
    address one = address(0x1001);
    address two = address(0x2002);

    function setUp() public {
        token = new MockToken();
        other = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(one, 300);
        vm.prank(one);
        market.deposit(address(token), 200);
    }

    // 結果の欄: 成功なら0、失敗なら巻き戻りデータの先頭4バイト
    function _try(address from, bytes memory data) internal returns (bytes4) {
        vm.prank(from);
        (bool ok, bytes memory ret) = address(market).call(data);
        return ok ? bytes4(0) : bytes4(ret);
    }

    // 一つの状態でaddAsset、deposit、withdraw、withdrawAll、setStatusを順に呼び、状態を元に戻す
    function _row(IMarket.MarketStatus s) internal returns (bytes4[5] memory r) {
        uint256 snap = vm.snapshotState();
        if (s != IMarket.MarketStatus.Active) market.setStatus(s);
        r[0] = _try(address(this), abi.encodeCall(IMarket.addAsset, (IERC20(address(other)), Ratio.wrap(50))));
        r[1] = _try(one, abi.encodeCall(IMarket.deposit, (address(token), 10)));
        r[2] = _try(one, abi.encodeCall(IMarket.withdraw, (address(token), 10)));
        r[3] = _try(one, abi.encodeCall(IMarket.withdrawAll, (address(token))));
        r[4] = _try(address(this), abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.Active)));
        vm.revertToState(snap);
    }

    function test_statusTable() public {
        bytes4 ok = bytes4(0);
        bytes4 notActive = IMarket.NotActive.selector;
        bytes4 frozen = IMarket.MarketFrozen.selector;

        bytes4[5] memory a = _row(IMarket.MarketStatus.Active);
        bytes4[5] memory p = _row(IMarket.MarketStatus.DepositPaused);
        bytes4[5] memory f = _row(IMarket.MarketStatus.Frozen);

        assertEq(abi.encode(a), abi.encode([ok, ok, ok, ok, ok]));
        assertEq(abi.encode(p), abi.encode([ok, notActive, ok, ok, ok]));
        assertEq(abi.encode(f), abi.encode([frozen, notActive, frozen, frozen, ok]));
    }

    function test_sameStatusEmits() public {
        vm.expectEmit(address(market));
        emit IMarket.StatusChanged(IMarket.MarketStatus.Active, IMarket.MarketStatus.Active);
        market.setStatus(IMarket.MarketStatus.Active);
    }

    function test_outOfRangeStatus() public {
        (bool ok, bytes memory ret) =
            address(market).call(abi.encodeWithSelector(IMarket.setStatus.selector, uint256(3)));
        assertFalse(ok);
        assertEq(ret.length, 0);
        assertEq(uint8(market.status()), 0);
    }

    function test_totalsMatchPositions() public {
        token.transfer(two, 100);
        vm.prank(two);
        market.deposit(address(token), 100);
        vm.prank(one);
        market.withdraw(address(token), 70);
        vm.prank(two);
        market.withdrawAll(address(token));
        vm.prank(one);
        market.deposit(address(token), 5);

        (Amount d1,,,) = market.positions(address(token), one);
        (Amount d2,,,) = market.positions(address(token), two);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), Amount.unwrap(d1) + Amount.unwrap(d2));
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), token.balanceOf(address(market)));
    }
}
