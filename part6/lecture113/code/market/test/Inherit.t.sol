// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, MarketBase, IERC20, Ratio, Rate, NotListed, ZeroAmount, NotActive} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第110講: 親から継承した状態変数も、Marketというデプロイ物一つのストレージにある
// 第112講: 親が三つでもスロットは基本側から。第109講の版のスロットマップのまま
// 第113講: 預け入れチェックの順番はwhenActive、上場確認(AssetRegistry)、金額確認(Ledger)。第109講の版と同じエラーが出なければならない
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

    // 第113講: 上場していない資産を0だけ預け入れると、上場確認が先に引っかかる
    function test_depositCheckOrder() public {
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        MockToken other = new MockToken();
        vm.expectRevert(abi.encodeWithSelector(NotListed.selector, address(other)));
        market.deposit(address(other), 0);
        vm.expectRevert(ZeroAmount.selector);
        market.deposit(address(token), 0);
        market.setStatus(MarketBase.MarketStatus.DepositPaused);
        vm.expectRevert(abi.encodeWithSelector(NotActive.selector, MarketBase.MarketStatus.DepositPaused));
        market.deposit(address(other), 0);
    }
}
