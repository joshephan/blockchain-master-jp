// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, MarketBase, IERC20, Ratio, Rate} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第110講: 親から継承した状態変数も、Marketというデプロイ物一つのストレージにある
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
}
