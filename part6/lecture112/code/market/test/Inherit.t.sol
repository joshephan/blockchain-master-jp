// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, MarketBase, IERC20, Ratio, Rate} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第110講: 親から継承した状態変数も、Marketというデプロイ物一つのストレージにある
// 第112講: 親が三つでもスロットは基本側から。第109講の版のスロットマップのまま
contract InheritTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // 第110講: MarketBaseのstatusはMarketのアドレスのスロット0
    function test_statusInSlotZero() public {
        market.setStatus(MarketBase.MarketStatus.Frozen);
        assertEq(uint256(vm.load(address(market), bytes32(uint256(0)))), 2);
    }

    // 第112講: AssetRegistryのassetsの長さはスロット1、LedgerのtotalDepositsはスロット4のマッピング
    function test_slotOrder() public {
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.deposit(address(token), 100);
        assertEq(uint256(vm.load(address(market), bytes32(uint256(1)))), 1);
        bytes32 slot = keccak256(abi.encode(address(token), uint256(4)));
        assertEq(uint256(vm.load(address(market), slot)), 100);
    }
}
