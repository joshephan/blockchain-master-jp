// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第141講: Marketが返すバイト列、出すログ、巻き戻りデータのABIの形。長さが決まった型だけなので頭だけで末尾なし
contract AbiShapeTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.deposit(address(token), 100);
    }

    function _ret(bytes memory cd) internal view returns (bytes memory data) {
        bool ok;
        (ok, data) = address(market).staticcall(cd);
        assertTrue(ok);
    }

    // 複数の戻り値はタプル一つにエンコード。値ごとに32バイトの欄、uint64・bool・uint8(Ratio、enum)も32バイト
    function test_returnDataBytes() public view {
        bytes memory p = _ret(abi.encodeCall(IMarket.positions, (address(token), address(this))));
        assertEq(p.length, 128);
        assertEq(p, abi.encode(uint256(100), uint256(0), uint64(block.timestamp), false));
        assertEq(_ret(abi.encodeCall(IMarket.assetConfig, (address(token)))), abi.encode(uint8(75), true));
        assertEq(_ret(abi.encodeCall(IMarket.status, ())), abi.encode(uint8(0)));
        assertEq(_ret(abi.encodeCall(IMarket.assets, (0))), abi.encode(address(token)));
    }

    // indexed引数はtopics、残りはdataに32バイトずつ
    function test_eventDataBytes() public {
        vm.recordLogs();
        market.setStatus(IMarket.MarketStatus.DepositPaused);
        market.withdraw(address(token), 30);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs[0].topics.length, 1); // StatusChanged: indexedなし
        assertEq(logs[0].data, abi.encode(uint8(0), uint8(1)));
        Vm.Log memory w = logs[logs.length - 1]; // Withdrawn
        assertEq(w.topics.length, 3);
        assertEq(w.data, abi.encode(uint256(30)));
    }

    // 巻き戻りデータはセレクター4バイト + 引数32バイトずつ。引数のないエラーは4バイト
    function test_errorDataBytes() public {
        vm.expectRevert(IMarket.ZeroAmount.selector); // 4バイト
        market.deposit(address(token), 0);
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, uint8(2))); // 36バイト
        market.deposit(address(token), 1);
    }
}
