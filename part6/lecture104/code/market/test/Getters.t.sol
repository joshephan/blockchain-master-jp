// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第96講: Marketのゲッターの形を確認
contract GettersTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.deposit(address(token), 100);
    }

    function test_positionsGetter() public view {
        (Amount deposited, Amount borrowed, uint64 lastUpdate, bool useAsCollateral) =
            market.positions(address(token), address(this));
        assertEq(Amount.unwrap(deposited), 100);
        assertEq(Amount.unwrap(borrowed), 0);
        assertEq(lastUpdate, uint64(block.timestamp));
        assertFalse(useAsCollateral);
    }

    function test_assetsGetter() public {
        assertEq(address(market.assets(0)), address(token));
        vm.expectRevert();
        market.assets(1);
    }

    function test_assetConfigGetter() public view {
        (Ratio ratio, bool listed) = market.assetConfig(address(token));
        assertEq(Ratio.unwrap(ratio), 75);
        assertTrue(listed);
    }
}
