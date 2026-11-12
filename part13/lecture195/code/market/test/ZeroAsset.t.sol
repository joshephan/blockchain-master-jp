// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第176講: lintのmissing-zero-checkが指すwithdrawのasset引数。ゼロアドレスのチェックを足さない根拠をテストで。
// 帳簿にない資産は預けた量が0なので、PositionLib.debitが先に巻き戻す。上場はaddAssetのZeroAssetが止める
contract ZeroAssetTest is Test {
    MockToken token;
    Market market;
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(bob, 100);
        vm.prank(bob);
        market.deposit(address(token), 100);
    }

    function test_withdrawZeroAssetReverts() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientDeposit.selector, 0, 1));
        market.withdraw(address(0), 1);
        (Amount d,,,) = market.positions(address(token), bob);
        assertEq(Amount.unwrap(d), 100);
    }

    function test_listZeroAssetReverts() public {
        vm.expectRevert(IMarket.ZeroAsset.selector);
        market.addAsset(IERC20(address(0)), Ratio.wrap(50));
    }

    // 管理者専用の二つは、管理者が開いたトランザクションの中でも、直接呼んだ側が管理者でなければ止まる
    function test_adminOnlyByCaller() public {
        vm.prank(bob, address(this));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.addAsset(IERC20(address(0xA55E7)), Ratio.wrap(50));
        vm.prank(bob, address(this));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.setStatus(IMarket.MarketStatus.Frozen);
        assertEq(market.assetCount(), 1);
        assertEq(uint8(market.status()), 0);
    }
}
