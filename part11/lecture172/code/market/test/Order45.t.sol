// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第45講(軸2)の確認テスト。Marketのsrcは変えない。軸2の攻撃面があるかだけを確認
contract Order45Test is Test {
    Market market;
    MockToken token;
    address admin = address(this);

    function setUp() public {
        market = new Market(admin, Rate.wrap(0), Ratio.wrap(80));
        token = new MockToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(50));
        token.transfer(address(this), 0); // 帳尻合わせ
    }

    // 預け入れと引き出しは帳簿と1:1。シェアの価格がないので、同じトランザクションで入れて出しても得がない
    // (フラッシュローンで揺さぶるシェアの価値がMarketにない)
    function test_depositWithdrawOneToOne() public {
        uint256 start = token.balanceOf(address(this));
        market.deposit(address(token), 100);
        (Amount d,,,) = market.positions(address(token), address(this));
        assertEq(Amount.unwrap(d), 100);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 100);
        market.withdraw(address(token), 100);
        (Amount d2,,,) = market.positions(address(token), address(this));
        assertEq(Amount.unwrap(d2), 0);
        assertEq(token.balanceOf(address(this)), start); // 引き出した量 = 入れた量、増えない
    }

    // Marketの唯一の軸2の接点はblock.timestamp(利息・lastUpdate)。ブロックを作る側が書く値
    function test_elapsedReadsBlockTimestamp() public {
        market.deposit(address(token), 100);
        assertEq(market.elapsedOf(address(token), address(this)), 0);
        vm.warp(vm.getBlockTimestamp() + 86_400);
        assertEq(market.elapsedOf(address(token), address(this)), 86_400);
    }

    // 同じブロック内のsetStatus(Frozen)とwithdrawの順番はブロックを作る側が決める(コードでは防げない)
    // 順番がsetStatusが先なら、withdrawがMarketFrozenで巻き戻る
    function test_freezeBeforeWithdrawBlocks() public {
        market.deposit(address(token), 100);
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.withdraw(address(token), 100);
    }

    // 順番がwithdrawが先なら、そのまま出ていく(同じ二つの取引、順番だけが違う)
    function test_withdrawBeforeFreezePasses() public {
        market.deposit(address(token), 100);
        market.withdraw(address(token), 100);
        market.setStatus(IMarket.MarketStatus.Frozen);
        (Amount d,,,) = market.positions(address(token), address(this));
        assertEq(Amount.unwrap(d), 0);
    }
}
