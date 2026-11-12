// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {FiatUSD} from "./FiatUSD54.sol";

// デモ用のコピー専用。発行体が凍結できるトークンを資産として上場したとき
contract StableAsset54Test is Test {
    Market market;
    FiatUSD fusd;
    address issuer = address(0x155);
    address alice = address(0xA11CE);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        fusd = new FiatUSD(issuer);
        market.addAsset(IERC20(address(fusd)), Ratio.wrap(75));
        vm.prank(issuer);
        fusd.mint(alice, 100e6);
        vm.startPrank(alice);
        fusd.approve(address(market), 100e6);
        market.deposit(address(fusd), 100e6);
        vm.stopPrank();
    }

    // 発行体がMarketのアドレスを凍結すると、帳簿に100があっても出金がトークンでリバートする
    function test_issuerFreezeBlocksWithdraw() public {
        vm.prank(issuer);
        fusd.setFrozen(address(market), true);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FiatUSD.AccountFrozen.selector, address(market)));
        market.withdraw(address(fusd), 100e6);
        (Amount d,,,) = market.positions(address(fusd), alice);
        assertEq(Amount.unwrap(d), 100e6);
        assertEq(fusd.balanceOf(address(market)), 100e6);
    }

    // 発行体が解除すればまた出ていく
    function test_unfreezeThenWithdraw() public {
        vm.startPrank(issuer);
        fusd.setFrozen(address(market), true);
        fusd.setFrozen(address(market), false);
        vm.stopPrank();
        vm.prank(alice);
        market.withdraw(address(fusd), 100e6);
        assertEq(fusd.balanceOf(alice), 100e6);
    }

    // Marketの管理者の鍵ではトークンの凍結を解けない
    function test_marketAdminCannotUnfreeze() public {
        vm.prank(issuer);
        fusd.setFrozen(address(market), true);
        vm.expectRevert(abi.encodeWithSelector(FiatUSD.NotIssuer.selector, address(this)));
        fusd.setFrozen(address(market), false);
    }
}
