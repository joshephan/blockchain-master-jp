// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第110講: 親から継承した状態変数も、Marketというデプロイ物一つのストレージにある
// 第112講: 親が三つでもスロットは基本側から。第109講の版のスロットマップのまま
// 第113講: 預け入れチェックの順番はwhenActive、上場確認(AssetRegistry)、金額確認(Ledger)。第109講の版と同じエラーが出なければならない
// 第114講: Marketのコンストラクタ引数が親のコンストラクタまで届く
// 第115講: MarketはIMarketを継承するので、IMarket型の変数にそのまま入る
contract InheritTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // 第110講: MarketBaseのstatusはMarketのアドレスのスロット0
    function test_statusInSlotZero() public {
        market.setStatus(IMarket.MarketStatus.Frozen);
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
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotListed.selector, address(other)));
        market.deposit(address(other), 0);
        vm.expectRevert(IMarket.ZeroAmount.selector);
        market.deposit(address(token), 0);
        market.setStatus(IMarket.MarketStatus.DepositPaused);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, IMarket.MarketStatus.DepositPaused));
        market.deposit(address(other), 0);
    }

    // 第114講: adminはMarketBase、collateralRatioはAssetRegistry、interestRateはMarketに入る
    function test_constructorArgsReachBases() public view {
        assertEq(market.admin(), address(this));
        assertEq(Ratio.unwrap(market.collateralRatio()), 80);
        assertEq(Rate.unwrap(market.interestRate()), 5e16);
    }

    // 第115講: 変換なしでIMarketの変数に入れ、IMarketとして呼ぶ
    function test_marketIsIMarket() public {
        IMarket im = market;
        im.addAsset(IERC20(address(token)), Ratio.wrap(75));
        im.setStatus(IMarket.MarketStatus.DepositPaused);
        assertEq(uint8(im.status()), 1);
        assertEq(im.assetCount(), 1);
    }
}
