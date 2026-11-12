// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {IMarket} from "../src/IMarket.sol";

// 自己監査の発見事項の確認テスト。テスト名の頭の番号がaudit/self-audit.mdの発見事項番号
// 直した版で通る形で先に書く。直す前の版ではスキップ(SKIP一つ = 直す仕事一つ)。直したあとも消さない
contract FindingsTest is Base {
    bytes4 constant ZERO_PRICE = bytes4(keccak256("ZeroPrice(address)"));
    bool constant FIXED = true;

    function setUp() public {
        _deploy(0);
        _openPosition();
    }

    // M-01: 平均価格0は止まった出どころと同じに扱う。借金の消去がリバートし、aliceの借金・担保はそのまま
    function test_M01_zeroPriceStopsWriteOff() public {
        vm.skip(!FIXED);
        _price(0);
        vm.expectRevert(abi.encodeWithSelector(ZERO_PRICE, address(col)));
        market.writeOffBadDebt(alice, address(usd));
        assertEq(market.debtOf(address(usd), alice), 700e6);
        assertEq(market.depositOf(address(col), alice), 1000e18);
    }

    // M-01: 平均価格0での清算は0除算のPanicではなくZeroPrice。返済はできる(T-01)
    function test_M01_zeroPriceStopsLiquidation() public {
        vm.skip(!FIXED);
        _price(0);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(ZERO_PRICE, address(col)));
        market.liquidate(alice, address(usd), address(col), 350e6);
        vm.prank(alice);
        market.repay(address(usd), 100e6);
        assertEq(market.debtOf(address(usd), alice), 600e6);
    }

    // M-01: 30分平均が0の出どころでは資産を上場しない(確認呼び出しの戻り値を使う)
    function test_M01_listAssetRejectsZeroAverage() public {
        vm.skip(!FIXED);
        StdToken t = new StdToken("T", "T", 18);
        TwapFeed f = new TwapFeed(0);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        vm.expectRevert(abi.encodeWithSelector(ZERO_PRICE, address(t)));
        market.listAsset(address(t), f, 50, type(uint256).max);
    }

    // L-01: 値が0に切り捨てられるくずの担保(18桁トークン1 wei、価格0.3)は担保がないものとして数える。借金の消去ができる
    // 修正案: 要件F-08の文をコード側(担保の値0)に合わせる。くずはアカウントに残る
    function test_L01_dustCollateralCountsAsNone() public {
        StdToken t = new StdToken("Tiny", "TINY", 18);
        TwapFeed f = new TwapFeed(0.3e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        market.listAsset(address(t), f, 50, type(uint256).max);
        t.mint(alice, 1);
        vm.startPrank(alice);
        t.approve(address(market), 1);
        market.deposit(address(t), 1);
        market.setCollateral(address(t), true);
        vm.stopPrank();
        _price(0.3e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 700e6);
        assertEq(market.depositOf(address(col), alice), 0);
        market.writeOffBadDebt(alice, address(usd));
        assertEq(market.depositOf(address(t), alice), 1);
    }

    // I-01: 担保としてオンにしていない預け金は清算・借金の消去が触らない(設計どおり、N-09)
    // aliceがUSD 200を担保としてオンにせず預けたまま借金を消し、その200はaliceが引き出す
    function test_I01_nonCollateralDepositStaysWithOwner() public {
        vm.prank(alice);
        market.deposit(address(usd), 200e6);
        _price(0.3e18);
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotCollateral.selector, address(usd)));
        market.liquidate(alice, address(usd), address(usd), 1e6);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 700e6);
        market.writeOffBadDebt(alice, address(usd));
        vm.prank(alice);
        market.withdrawAll(address(usd));
        assertEq(market.depositOf(address(usd), alice), 0);
    }
}
