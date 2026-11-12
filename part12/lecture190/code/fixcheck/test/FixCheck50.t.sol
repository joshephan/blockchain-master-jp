// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 修正の確認: 第164講の版でM-01を再現したテストを、そのまま直した版で回す
contract FixCheck50Test is Test {
    Market market;
    MockToken token;
    address alice = address(0xA11CE);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(alice, 200);
    }

    // M-01: 管理者がFrozenをかけると、預けた人は誰も引き出せない。管理者の席を譲ったり空にしたりする関数なし
    function test_M01_frozenLocksWithdraw() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.prank(alice);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.withdraw(address(token), 100);
        vm.prank(alice);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.withdrawAll(address(token));
        (Amount d,,,) = market.positions(address(token), alice);
        assertEq(Amount.unwrap(d), 100);
        assertEq(token.balanceOf(address(market)), 100);
    }
}
