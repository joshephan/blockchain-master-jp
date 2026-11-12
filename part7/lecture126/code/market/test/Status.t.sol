// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第103講: modifier四つ(onlyAdmin、notFrozen、whenActive、onlyListed)とsetStatus
// 第108講: 文字列の代わりにエラーデータで照合。引数のあるエラーはabi.encodeWithSelector、引数のないエラーはセレクターだけ
contract StatusTest is Test {
    MockToken token;
    MockToken other;
    Market market;
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockToken();
        other = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.deposit(address(token), 100);
    }

    function test_setStatusOnlyAdmin() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.setStatus(IMarket.MarketStatus.Frozen);
        market.setStatus(IMarket.MarketStatus.Frozen);
        assertEq(uint8(market.status()), 2);
    }

    // addAssetはonlyAdmin notFrozenの順番: 管理者でない側が凍結した市場で呼ぶと、前のものが先に引っかかる
    function test_addAssetOrder() public {
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.addAsset(IERC20(address(other)), Ratio.wrap(50));
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.addAsset(IERC20(address(other)), Ratio.wrap(50));
    }

    function test_depositPaused() public {
        market.setStatus(IMarket.MarketStatus.DepositPaused);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, IMarket.MarketStatus.DepositPaused));
        market.deposit(address(token), 1);
        market.withdraw(address(token), 40); // 引き出しはできる
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 60);
    }

    // withdrawAllはmodifierがないが、内部で呼ぶwithdrawのnotFrozenを通る
    function test_frozenBlocksWithdrawAll() public {
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.withdraw(address(token), 1);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.withdrawAll(address(token));
    }

    // whenActive onlyListed(asset)の順番: 引数を受け取るmodifierは自分の番で引数を計算
    function test_depositNotListed() public {
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotListed.selector, address(other)));
        market.deposit(address(other), 1);
    }
}
