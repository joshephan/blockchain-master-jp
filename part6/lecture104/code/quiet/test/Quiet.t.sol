// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第104講のデモ用(プロジェクトではない): notFrozenを巻き戻さずに飛ばすように変えた版
contract QuietTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.deposit(address(token), 100);
    }

    function test_frozenWithdrawLooksFine() public {
        market.setStatus(Market.MarketStatus.Frozen);
        market.withdraw(address(token), 40); // 巻き戻らない
        assertEq(token.balanceOf(address(this)), 900); // トークンは来なかった
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 100);
    }
}
